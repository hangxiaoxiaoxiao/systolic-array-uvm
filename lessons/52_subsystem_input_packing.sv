// Lesson 52: turn one complete A/B pair into M subsystem input words.
// Ordinary SystemVerilog; top: subsystem_input_packing_demo. No UVM required.
// Fixed teaching example: DIN_WIDTH=8, N=2, M=3, BUS_WIDTH=32.
// The PDF specifies N A-column elements and N B-row elements per input word.
// It does NOT specify their bit order. This file adopts a TEACHING ASSUMPTION:
//   low N*DIN_WIDTH bits: A column, increasing row index toward higher bits;
//   high N*DIN_WIDTH bits: B row, increasing column index toward higher bits.
// For N=2: din = {B[k][1], B[k][0], A[1][k], A[0][k]}.
// These are data words, not a FIFO handshake or a systolic-array cycle schedule.
// No wr_fifo, full flag, clocks, DUT, matrix arithmetic, or actual FIFO exists here.
// +INJECT_ERROR flips word 1 bit 0; the independent known-word check must reject it.
module subsystem_input_packing_demo;
  localparam int DIN_WIDTH = 8;
  localparam int N = 2;
  localparam int M = 3;
  localparam int BUS_WIDTH = 2 * DIN_WIDTH * N;

  logic signed [DIN_WIDTH-1:0] A[0:N-1][0:M-1];
  logic signed [DIN_WIDTH-1:0] B[0:M-1][0:N-1];
  logic [BUS_WIDTH-1:0] words[0:M-1];
  logic [BUS_WIDTH-1:0] known_words[0:M-1];

  function automatic logic [BUS_WIDTH-1:0] pack_input_word(input int k);
    logic [BUS_WIDTH-1:0] packed_word;
    if (k < 0 || k >= M) begin
      $fatal(1, "WORD_INDEX: k=%0d is outside 0..%0d", k, M-1);
      return '0;
    end
    packed_word = '0;
    for (int i = 0; i < N; i++)
      packed_word[i*DIN_WIDTH +: DIN_WIDTH] = A[i][k];
    for (int j = 0; j < N; j++)
      packed_word[(N+j)*DIN_WIDTH +: DIN_WIDTH] = B[k][j];
    return packed_word;
  endfunction

  initial begin
    logic signed [DIN_WIDTH-1:0] decoded_a, decoded_b;
    int checked_words, checked_elements;
    checked_words = 0;
    checked_elements = 0;

    A[0][0] =  8'sd1; A[0][1] = -8'sd2; A[0][2] =  8'sd3;
    A[1][0] =  8'sd4; A[1][1] =  8'sd5; A[1][2] = -8'sd6;
    B[0][0] =  8'sd7; B[0][1] =  8'sd8;
    B[1][0] = -8'sd9; B[1][1] =  8'sd10;
    B[2][0] =  8'sd11; B[2][1] = -8'sd12;

    // Independent literal oracles, not computed by pack_input_word or unpacking.
    known_words[0] = 32'h08070401;
    known_words[1] = 32'h0AF705FE;
    known_words[2] = 32'hF40BFA03;

    $display("PACKING_ASSUMPTION: low half=A column, high half=B row; lane 0 is lowest");
    for (int k = 0; k < M; k++) begin
      words[k] = pack_input_word(k);
      if (k == 1 && $test$plusargs("INJECT_ERROR")) begin
        words[k][0] = ~words[k][0];
        $display("INJECT_ERROR: flipped bit 0 of word k=1");
      end
      if (words[k] !== known_words[k])
        $fatal(1, "PACKING_MISMATCH: k=%0d packed=%08h known=%08h",
               k, words[k], known_words[k]);
      checked_words++;
      $display("WORD: k=%0d din=%08h", k, words[k]);

      // A packed slice contains raw bits. Assign it to a signed element before
      // displaying/using its numeric value so FE/F7/FA/F4 remain negative.
      for (int lane = 0; lane < N; lane++) begin
        decoded_a = words[k][lane*DIN_WIDTH +: DIN_WIDTH];
        decoded_b = words[k][(N+lane)*DIN_WIDTH +: DIN_WIDTH];
        if (decoded_a !== A[lane][k] || decoded_b !== B[k][lane])
          $fatal(1, "UNPACK_MISMATCH: k=%0d lane=%0d", k, lane);
        checked_elements += 2;
        $display("  lane=%0d A[%0d][%0d]=%0d B[%0d][%0d]=%0d",
                 lane, lane, k, decoded_a, k, lane, decoded_b);
      end
    end

    if (checked_words != M || checked_elements != 2*N*M)
      $fatal(1, "CHECK_COUNT: expected 3 words / 12 elements, got %0d / %0d",
             checked_words, checked_elements);
    $display("PACKING_DEMO_PASS: 3 words and 12 signed elements matched the chosen layout; no FIFO transfers checked.");
    $finish;
  end
endmodule
