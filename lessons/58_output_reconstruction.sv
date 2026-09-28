`timescale 1ns/1ps
// Lesson 58: reconstruct C from accepted reads of a teaching output FIFO.
// Ordinary SV; top: output_reconstruction_demo. No UVM or interview RTL.
// INPUT teaching contract from lesson 53, not confirmed by the PDF:
//   writes are accepted at posedge using pre-edge wr_fifo && !in_fifo_full;
//   the writer drives at negedge and waits while the one-slot input model is full.
// consume_enable is the input model's internal consumer, not external rd_fifo.
// OUTPUT teaching contract, also not confirmed by the PDF:
//   FWFT: while nonempty, dout already shows the current head word;
//   reads are accepted at posedge using pre-edge rd_fifo && !out_fifo_empty;
//   pointer NBA updates occur after the monitor samples the old head word.
// Each output word represents one C row: low 16 bits=column 0, high=column 1.
// Output storage is preloaded once with independent literal words, not computed C.
// This single-clock fixture is NOT a complete FIFO or a systolic-array DUT model.
// There is no sr_clk, CDC, hardware matrix computation, or specified DUT latency.
// Fixed M=3, N=2; first input/output accepted word after reset starts its frame.
// +INJECT_RESULT_ERROR changes the second row's first element from -83 to -82.
// +DROP_LAST_ROW loads only the first row and takes precedence over that mutation.
// Completion follows finite fixture exhaustion, not a deadline for real hardware.
module output_reconstruction_demo;
  localparam int DIN_WIDTH = 8;
  localparam int N = 2;
  localparam int M = 3;
  localparam int BUS_WIDTH = 2 * DIN_WIDTH * N;
  localparam int WORD_COUNT = M;
  localparam int PRODUCT_WIDTH = 2 * DIN_WIDTH;
  localparam int EXTRA_BITS = (M > 1) ? $clog2(M) : 0;
  localparam int ACC_WIDTH = PRODUCT_WIDTH + EXTRA_BITS;
  localparam logic signed [PRODUCT_WIDTH-1:0] OUTPUT_MIN_NARROW =
    {1'b1, {(PRODUCT_WIDTH-1){1'b0}}};
  localparam logic signed [PRODUCT_WIDTH-1:0] OUTPUT_MAX_NARROW =
    {1'b0, {(PRODUCT_WIDTH-1){1'b1}}};
  localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MIN = OUTPUT_MIN_NARROW;
  localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MAX = OUTPUT_MAX_NARROW;

  logic sys_clk = 0;
  logic rst_n = 0;
  logic [BUS_WIDTH-1:0] din = '0;
  logic wr_fifo = 0;
  wire in_fifo_full;
  logic consume_enable = 0;
  logic occupied;
  logic [BUS_WIDTH-1:0] slot;
  wire accepted_write = wr_fifo && !in_fifo_full;
  wire consumed_word = consume_enable && occupied;

  logic rd_fifo = 0;
  wire out_fifo_empty;
  wire [BUS_WIDTH-1:0] dout;
  wire accepted_read = rd_fifo && !out_fifo_empty;
  logic [BUS_WIDTH-1:0] output_storage[0:N-1];
  bit output_loaded = 0;
  int output_length = 0;
  int output_read_ptr;
  int output_word_count = 0;
  int output_row = 0;

  logic [BUS_WIDTH-1:0] prepared_words[0:WORD_COUNT-1];
  int accepted_count = 0;
  int consumed_count = 0;
  int waiting_edges = 0;
  logic signed [DIN_WIDTH-1:0] observed_A[0:N-1][0:M-1];
  logic signed [DIN_WIDTH-1:0] observed_B[0:M-1][0:N-1];
  logic signed [DIN_WIDTH-1:0] known_A[0:N-1][0:M-1];
  logic signed [DIN_WIDTH-1:0] known_B[0:M-1][0:N-1];
  int rebuild_k = 0;
  int completed_frames = 0;
  int checked_elements = 0;
  logic signed [ACC_WIDTH-1:0] C_full[0:N-1][0:N-1];
  logic fits_output[0:N-1][0:N-1];
  logic signed [ACC_WIDTH-1:0] C_known[0:N-1][0:N-1];
  int reference_calls = 0;
  int checked_results = 0;
  logic signed [PRODUCT_WIDTH-1:0] C_observed[0:N-1][0:N-1];
  bit prediction_pending = 0;
  int compared_matrices = 0;
  int compared_elements = 0;
  int mismatch_count = 0;
  bit output_source_done = 0;

  always #5 sys_clk = ~sys_clk;
  assign in_fifo_full = occupied;
  // One preload only, with at most N rows. Empty output data are not meaningful.
  assign out_fifo_empty = !output_loaded || (output_read_ptr >= output_length);
  assign dout = out_fifo_empty ? '0 : output_storage[output_read_ptr];

  // The old head remains visible during posedge monitor sampling.
  always @(posedge sys_clk) begin
    if (!rst_n)
      output_read_ptr <= 0;
    else if (accepted_read)
      output_read_ptr <= output_read_ptr + 1;
  end

  // Synchronous reset is another local teaching choice.
  // Nonblocking assignments leave pre-edge occupancy/data visible to observers.
  always @(posedge sys_clk) begin
    if (!rst_n) begin
      occupied <= 0;
      slot <= '0;
    end else begin
      if (accepted_write) begin
        slot <= din;
        occupied <= 1;
      end else if (consumed_word) begin
        occupied <= 0;
      end
    end
  end

  // Independent literal oracle: never read the driver's prepared_words array.
  function automatic logic [BUS_WIDTH-1:0] expected_word(input int index);
    case (index)
      0: return 32'h08070401;
      1: return 32'h0AF705FE;
      2: return 32'hF40BFA03;
      default: begin
        $fatal(1, "EXTRA_WORD: index=%0d", index);
        return 'x;
      end
    endcase
  endfunction

  // Independent matrix-element oracle, not values unpacked from prepared_words.
  task automatic check_reconstructed_frame;
    for (int i = 0; i < N; i++) begin
      for (int k = 0; k < M; k++) begin
        if (observed_A[i][k] !== known_A[i][k])
          $fatal(1, "REBUILD_A: A[%0d][%0d] actual=%0d expected=%0d",
                 i, k, observed_A[i][k], known_A[i][k]);
        checked_elements++;
        $display("REBUILT_A: A[%0d][%0d]=%0d", i, k, observed_A[i][k]);
      end
    end
    for (int k = 0; k < M; k++) begin
      for (int j = 0; j < N; j++) begin
        if (observed_B[k][j] !== known_B[k][j])
          $fatal(1, "REBUILD_B: B[%0d][%0d] actual=%0d expected=%0d",
                 k, j, observed_B[k][j], known_B[k][j]);
        checked_elements++;
        $display("REBUILT_B: B[%0d][%0d]=%0d", k, j, observed_B[k][j]);
      end
    end
  endtask

  // Read only the monitor's reconstructed inputs, never known_A/B or driver data.
  function automatic void calculate_reference_from_observed();
    logic signed [DIN_WIDTH-1:0] input_value;
    logic signed [PRODUCT_WIDTH-1:0] product;
    logic signed [ACC_WIDTH-1:0] extended_product, sum;

    if (rebuild_k != M || completed_frames != 1)
      $fatal(1, "REFERENCE_BEFORE_FRAME: input frame is not complete");
    reference_calls++;

    // Retain lesson 36's scalar copy for this Icarus version's $isunknown check.
    foreach (observed_A[i,k]) begin
      input_value = observed_A[i][k];
      if ($isunknown(input_value))
        $fatal(1, "UNKNOWN_INPUT: observed_A[%0d][%0d] contains X/Z", i, k);
    end
    foreach (observed_B[k,j]) begin
      input_value = observed_B[k][j];
      if ($isunknown(input_value))
        $fatal(1, "UNKNOWN_INPUT: observed_B[%0d][%0d] contains X/Z", k, j);
    end

    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        sum = '0;
        for (int k = 0; k < M; k++) begin
          product = observed_A[i][k] * observed_B[k][j];
          // EXTRA_BITS can be zero for M=1; the product is still present.
          extended_product = {{EXTRA_BITS{product[PRODUCT_WIDTH-1]}}, product};
          sum = sum + extended_product;
        end
        C_full[i][j] = sum;
        fits_output[i][j] = (sum >= OUTPUT_MIN) && (sum <= OUTPUT_MAX);
      end
    end
  endfunction

  // These constants check the reference integration; they are not DUT outputs.
  task automatic check_prediction;
    foreach (C_full[i, j]) begin
      if (C_full[i][j] !== C_known[i][j] || fits_output[i][j] !== 1'b1)
        $fatal(1, "PREDICTION_MISMATCH: C[%0d][%0d] full=%0d known=%0d fits=%b",
               i, j, C_full[i][j], C_known[i][j], fits_output[i][j]);
      checked_results++;
      $display("EXPECTED_C: C[%0d][%0d]=%0d fits_output=%b",
               i, j, C_full[i][j], fits_output[i][j]);
    end
  endtask

  // Only one pending prediction exists in this single-frame teaching example.
  // Processing a result consumes it even when some values mismatch.
  task automatic compare_observed_result;
    logic signed [PRODUCT_WIDTH-1:0] actual_element;
    logic signed [ACC_WIDTH-1:0] actual_full;
    if (!prediction_pending)
      $fatal(1, "NO_PREDICTION: observed result has no pending expectation");
    // Check the entire prediction before comparing any numerical values.
    foreach (fits_output[i, j]) begin
      if (fits_output[i][j] !== 1'b1)
        $fatal(1, "REFERENCE_NOT_COMPARABLE: C[%0d][%0d] needs an agreed overflow policy", i, j);
    end
    foreach (C_observed[i, j]) begin
      actual_element = C_observed[i][j];
      actual_full = {{EXTRA_BITS{actual_element[PRODUCT_WIDTH-1]}}, actual_element};
      compared_elements++;
      if (actual_full !== C_full[i][j]) begin
        mismatch_count++;
        $display("RESULT_MISMATCH: C[%0d][%0d] sampled=%0d expected=%0d",
                 i, j, actual_full, C_full[i][j]);
      end else begin
        $display("RESULT_MATCH: C[%0d][%0d] sampled=%0d expected=%0d",
                 i, j, actual_full, C_full[i][j]);
      end
    end
    prediction_pending = 0;
    compared_matrices++;
    $display("RESULT_PROCESSED: matrices=%0d elements=%0d mismatches=%0d pending=%b",
             compared_matrices, compared_elements, mismatch_count, prediction_pending);
  endtask

  // A zero mismatch count is insufficient if the expected result never arrived.
  task automatic check_completion;
    int completion_errors;
    if (!output_source_done)
      $fatal(1, "SOURCE_NOT_DONE: do not check final counts before the finite output source ends and is drained");
    completion_errors = 0;
    if (output_word_count != completed_frames*N) begin
      completion_errors++;
      $display("OUTPUT_WORD_COUNT: input_frames=%0d words=%0d expected_words=%0d",
               completed_frames, output_word_count, completed_frames*N);
    end
    if (compared_matrices != completed_frames) begin
      completion_errors++;
      $display("MATRIX_COUNT: input_frames=%0d compared_matrices=%0d",
               completed_frames, compared_matrices);
    end
    if (prediction_pending) begin
      completion_errors++;
      $display("PENDING_RESULT: one prediction still has no compared result");
    end
    // This checks completeness of results actually received, not their quantity.
    if (compared_elements != compared_matrices*N*N) begin
      completion_errors++;
      $display("ELEMENT_COUNT: compared_matrices=%0d compared_elements=%0d",
               compared_matrices, compared_elements);
    end
    if (mismatch_count != 0) begin
      completion_errors++;
      $display("VALUE_MISMATCHES: %0d numerical mismatches", mismatch_count);
    end
    $display("COMPLETION_STATE: input_frames=%0d reference_calls=%0d output_words=%0d assembled_rows=%0d compared_matrices=%0d compared_elements=%0d mismatches=%0d pending=%b source_done=%b errors=%0d",
             completed_frames, reference_calls, output_word_count, output_row,
             compared_matrices, compared_elements, mismatch_count,
             prediction_pending, output_source_done, completion_errors);
    if (completion_errors != 0)
      $fatal(1, "COMPLETION_FAILED: %0d failed completion checks", completion_errors);
  endtask

  // A separate output monitor: read only interface signals, not storage/driver state.
  // Blocking assignments include the last row before comparison is called.
  always @(posedge sys_clk) begin
    if (!rst_n) begin
      output_word_count = 0;
      output_row = 0;
      foreach (C_observed[i, j]) C_observed[i][j] = 'x;
    end else begin
      if ((rd_fifo !== 1'b0 && rd_fifo !== 1'b1) ||
          (out_fifo_empty !== 1'b0 && out_fifo_empty !== 1'b1))
        $fatal(1, "UNKNOWN_OUTPUT_CONTROL");
      if (rd_fifo && out_fifo_empty)
        $fatal(1, "READ_WHILE_EMPTY: reader violated this lesson's contract");
      if (accepted_read) begin
        if (output_row >= N)
          $fatal(1, "EXTRA_OUTPUT_ROW: this lesson expects one result matrix");
        for (int j = 0; j < N; j++)
          C_observed[output_row][j] = dout[j*PRODUCT_WIDTH +: PRODUCT_WIDTH];
        $display("OUTPUT_SAMPLE: t=%0t row=%0d dout=%08h C0=%0d C1=%0d",
                 $time, output_row, dout, C_observed[output_row][0], C_observed[output_row][1]);
        output_word_count++;
        output_row++;
        if (output_row == N)
          compare_observed_result();
      end
    end
  end

  // Only accepted input pin data populate the input monitor's arrays.
  // Blocking assignments are deliberate: check the final column/row after it is copied.
  always @(posedge sys_clk) begin
    if (!rst_n) begin
      accepted_count = 0;
      consumed_count = 0;
      rebuild_k = 0;
      completed_frames = 0;
      checked_elements = 0;
      reference_calls = 0;
      checked_results = 0;
      prediction_pending = 0;
      compared_matrices = 0;
      compared_elements = 0;
      mismatch_count = 0;
      foreach (C_full[i, j]) begin
        C_full[i][j] = 'x;
        fits_output[i][j] = 1'bx;
      end
      foreach (observed_A[i, k]) observed_A[i][k] = 'x;
      foreach (observed_B[k, j]) observed_B[k][j] = 'x;
    end else begin
      if ((wr_fifo !== 1'b0 && wr_fifo !== 1'b1) ||
          (in_fifo_full !== 1'b0 && in_fifo_full !== 1'b1) ||
          (consume_enable !== 1'b0 && consume_enable !== 1'b1))
        $fatal(1, "UNKNOWN_CONTROL");
      if (wr_fifo && in_fifo_full)
        $fatal(1, "WRITER_CONTRACT: wr_fifo must be low while full in this lesson");
      if (accepted_write) begin
        if (din !== expected_word(accepted_count))
          $fatal(1, "ACCEPT_ORDER: index=%0d actual=%08h expected=%08h",
                 accepted_count, din, expected_word(accepted_count));
        $display("ACCEPT: t=%0t index=%0d din=%08h",
                 $time, accepted_count, din);
        accepted_count++;

        if (rebuild_k >= M)
          $fatal(1, "EXTRA_FRAME_DATA: this lesson expects exactly one frame");
        for (int lane = 0; lane < N; lane++) begin
          observed_A[lane][rebuild_k] = din[lane*DIN_WIDTH +: DIN_WIDTH];
          observed_B[rebuild_k][lane] = din[(N+lane)*DIN_WIDTH +: DIN_WIDTH];
        end
        $display("REBUILD_SAMPLE: t=%0t k=%0d", $time, rebuild_k);
        rebuild_k++;
        if (rebuild_k == M) begin
          check_reconstructed_frame();
          completed_frames++;
          $display("FRAME_COMPLETE: t=%0t frames=%0d", $time, completed_frames);
          calculate_reference_from_observed();
          check_prediction();
          prediction_pending = 1;
          $display("PREDICTION_READY: t=%0t; mathematical expectation only, no DUT result", $time);
        end
      end
      if (consumed_word) begin
        if (slot !== expected_word(consumed_count))
          $fatal(1, "CONSUME_ORDER: index=%0d actual=%08h expected=%08h",
                 consumed_count, slot, expected_word(consumed_count));
        $display("CONSUME: t=%0t index=%0d data=%08h",
                 $time, consumed_count, slot);
        consumed_count++;
      end
    end
  end

  // Pause consumption long enough to force full-induced waiting.
  initial begin
    wait (rst_n === 1'b1);
    repeat (6) @(negedge sys_clk);
    consume_enable = 1;
  end

  initial begin : writer_and_completion
    int next_word;
    $timeformat(-9, 0, " ns", 0);
    // Reuse the three words prepared in lesson 52, with its assumed bit layout.
    prepared_words[0] = 32'h08070401;
    prepared_words[1] = 32'h0AF705FE;
    prepared_words[2] = 32'hF40BFA03;
    // Handwritten signed values independently verify the reconstruction layout.
    known_A[0][0] =  8'sd1; known_A[0][1] = -8'sd2; known_A[0][2] =  8'sd3;
    known_A[1][0] =  8'sd4; known_A[1][1] =  8'sd5; known_A[1][2] = -8'sd6;
    known_B[0][0] =  8'sd7; known_B[0][1] =  8'sd8;
    known_B[1][0] = -8'sd9; known_B[1][1] =  8'sd10;
    known_B[2][0] =  8'sd11; known_B[2][1] = -8'sd12;
    // Hand-calculated C, independent of calculate_reference_from_observed().
    C_known[0][0] =  18'sd58; C_known[0][1] = -18'sd48;
    C_known[1][0] = -18'sd83; C_known[1][1] =  18'sd154;
    next_word = 0;

    repeat (2) @(negedge sys_clk);
    rst_n = 1;
    while (next_word < WORD_COUNT) begin
      @(negedge sys_clk);
      if (in_fifo_full !== 1'b0 && in_fifo_full !== 1'b1)
        $fatal(1, "UNKNOWN_FULL");
      din = prepared_words[next_word];
      wr_fifo = !in_fifo_full;

      @(posedge sys_clk);
      if (accepted_write) begin
        next_word++;
      end else begin
        waiting_edges++;
        $display("WAIT_FULL: t=%0t keep_index=%0d", $time, next_word);
      end
    end

    @(negedge sys_clk);
    wr_fifo = 0;
    wait (consumed_count == WORD_COUNT);
    @(negedge sys_clk);
    if (accepted_count != WORD_COUNT || consumed_count != WORD_COUNT ||
        in_fifo_full !== 1'b0 || waiting_edges == 0)
      $fatal(1, "COMPLETION: accepted=%0d consumed=%0d full=%b waits=%0d",
             accepted_count, consumed_count, in_fifo_full, waiting_edges);
    if (rebuild_k != M || completed_frames != 1 || checked_elements != 2*N*M)
      $fatal(1, "FRAME_COUNTS: k=%0d frames=%0d checked_elements=%0d",
             rebuild_k, completed_frames, checked_elements);
    if (reference_calls != 1 || checked_results != N*N)
      $fatal(1, "PREDICTION_COUNTS: calls=%0d checked_results=%0d",
             reference_calls, checked_results);
    // Independent literal source: never read C_full, C_known, or observed A/B.
    // row 0 = {16'hFFD0 (-48), 16'h003A (58)}
    // row 1 = {16'h009A (154), 16'hFFAD (-83)}
    output_storage[0] = 32'hFFD0003A;
    output_storage[1] = 32'h009AFFAD;
    output_length = N;
    if ($test$plusargs("DROP_LAST_ROW")) begin
      output_length = N-1;
      $display("DROP_LAST_ROW: only the first output row will be available");
      if ($test$plusargs("INJECT_RESULT_ERROR"))
        $display("DROP_PRECEDENCE: absent second row is not mutated or submitted");
    end else if ($test$plusargs("INJECT_RESULT_ERROR")) begin
      output_storage[1] = 32'h009AFFAE;
      $display("INJECT_RESULT_ERROR: output row 1 contains -82 instead of -83");
    end
    output_loaded = 1;
    $display("OUTPUT_PRELOAD: t=%0t words=%0d; independent fixture, not DUT computation", $time, output_length);

    // Drive at negedge, sample at posedge, inspect updated empty at the NEXT negedge.
    // Drain the actual finite source; do not wait for the expected number of rows.
    @(negedge sys_clk);
    while (out_fifo_empty === 1'b0) begin
      rd_fifo = 1;
      @(posedge sys_clk);
      @(negedge sys_clk);
    end
    rd_fifo = 0;
    if (out_fifo_empty !== 1'b1)
      $fatal(1, "OUTPUT_NOT_DRAINED: expected a known empty flag");
    output_source_done = 1;
    check_completion();
    $display("OUTPUT_RECONSTRUCTION_PASS: one result sampled and compared; independent fixture, no interview RTL checked.");
    $finish;
  end

  initial begin
    #500;
    $fatal(1, "WATCHDOG: teaching example did not complete within 500 ns");
  end
endmodule
