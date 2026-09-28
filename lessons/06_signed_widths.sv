// Lesson 6: signed 8-bit inputs and signed 16-bit outputs.
// Fixed small dimensions keep the 32-bit reference accumulator sufficient.
// No DUT is connected; C_actual contains independently hand-calculated answers.
module signed_widths;
  localparam int DIN_WIDTH = 8;
  localparam int N = 2;
  localparam int M = 2;

  logic signed [DIN_WIDTH-1:0] A[0:N-1][0:M-1];
  logic signed [DIN_WIDTH-1:0] B[0:M-1][0:N-1];
  logic signed [2*DIN_WIDTH-1:0] C_expected[0:N-1][0:N-1];
  logic signed [2*DIN_WIDTH-1:0] C_actual[0:N-1][0:N-1];

  function automatic void calculate_expected();
    int signed product;
    int signed sum;
    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        sum = 0;
        for (int k = 0; k < M; k++) begin
          // Signed operands; the 32-bit assignment context preserves the product.
          product = A[i][k] * B[k][j];
          sum += product;
        end

        // These bounds apply to this lesson's signed 16-bit output.
        // The PDF does not define overflow behavior: do not silently choose
        // wrapping or saturation. This lesson uses only in-range results.
        if (sum < -32768 || sum > 32767)
          $fatal(1, "C[%0d][%0d]=%0d exceeds the lesson's 16-bit output range", i, j, sum);
        C_expected[i][j] = sum;
      end
    end
  endfunction

  function automatic int count_mismatches();
    int errors;
    errors = 0;
    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        if (C_actual[i][j] !== C_expected[i][j]) begin
          errors++;
          $display("MISMATCH C[%0d][%0d]: expected=%0d actual=%0d",
                   i, j, C_expected[i][j], C_actual[i][j]);
        end
      end
    end
    return errors;
  endfunction

  initial begin
    $display("Input element width: %0d; output element width: %0d",
             $bits(A[0][0]), $bits(C_expected[0][0]));

    A[0][0] = 1;  A[0][1] = -2;
    A[1][0] = 3;  A[1][1] =  4;
    B[0][0] = -1; B[0][1] =  2;
    B[1][0] =  5; B[1][1] = -3;
    C_actual[0][0] = -11; C_actual[0][1] =  8;
    C_actual[1][0] =  17; C_actual[1][1] = -6;
    calculate_expected();
    if (count_mismatches() != 0)
      $fatal(1, "Mixed-sign example failed");
    $display("PASS: mixed-sign example");

    // Signed input endpoints. Each output here has one nonzero product.
    A[0][0] = -128; A[0][1] = 0;
    A[1][0] =  127; A[1][1] = 0;
    B[0][0] = -128; B[0][1] = 127;
    B[1][0] =    0; B[1][1] =   0;
    C_actual[0][0] =  16384; C_actual[0][1] = -16256;
    C_actual[1][0] = -16256; C_actual[1][1] =  16129;
    calculate_expected();
    if (count_mismatches() != 0)
      $fatal(1, "Signed input endpoint example failed");
    $display("PASS: signed input endpoints; C[0][0]=%0d", C_expected[0][0]);

    // Optional check that an out-of-range reference sum is reported.
    if ($test$plusargs("CHECK_OVERFLOW_GUARD")) begin
      A[0][1] = -128;
      B[1][0] = -128;
      calculate_expected();
      $fatal(1, "The overflow guard should have stopped calculation");
    end

    $finish;
  end
endmodule
