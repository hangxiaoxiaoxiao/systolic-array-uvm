`timescale 1ns/1ps
// Lesson 55: predict C from one fully reconstructed, accepted A/B frame.
// Ordinary SV; top: observed_reference_demo. No UVM or interview DUT.
// TEACHING CONTRACT, not confirmed by the PDF:
//   a write is accepted at posedge sys_clk when pre-edge wr_fifo && !full;
//   the writer drives at negedge and deasserts wr_fifo while full;
//   a full slot cannot accept a write even if consumed on that same edge.
// A one-slot, single-clock model creates real occupancy-based backpressure.
// consume_enable is an INTERNAL teaching consumer, NOT the PDF's rd_fifo.
// There is no sr_clk, CDC, output FIFO, or hardware matrix computation here.
// The reference is zero-time mathematics; prediction readiness is NOT DUT latency.
// Fixed M=3; the first accepted word after initial reset is assumed to be k=0.
// This single-frame boundary convention is not established by the PDF.
// Packing assumption from lesson 52: low half=A column, high half=B row.
// +INJECT_PREDICTION_ERROR corrupts one computed prediction before its self-check.
module observed_reference_demo;
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

  always #5 sys_clk = ~sys_clk;
  assign in_fifo_full = occupied;

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

  // Only accepted pin data populate the monitor's arrays.
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
          if ($test$plusargs("INJECT_PREDICTION_ERROR")) begin
            C_full[0][0] = C_full[0][0] + 18'sd1;
            $display("INJECT_PREDICTION_ERROR: changed predicted C[0][0] to %0d", C_full[0][0]);
          end
          check_prediction();
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
    $display("OBSERVED_REFERENCE_PASS: frames=%0d input_elements=%0d reference_calls=%0d results=%0d accepted=%0d consumed=%0d waits=%0d; no DUT result checked.",
             completed_frames, checked_elements, reference_calls, checked_results,
             accepted_count, consumed_count, waiting_edges);
    $finish;
  end

  initial begin
    #500;
    $fatal(1, "WATCHDOG: teaching example did not complete within 500 ns");
  end
endmodule
