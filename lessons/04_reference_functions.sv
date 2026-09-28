// Lesson 4: reuse the reference calculation and checker for two examples.
// No DUT is connected; C_actual contains manually supplied sample results.
// These teaching functions use shared module arrays, not a final UVM API.
module reference_functions;
  int signed A[0:1][0:1];
  int signed B[0:1][0:1];
  int signed C_expected[0:1][0:1];
  int signed C_actual[0:1][0:1];

  function automatic void calculate_expected();
    for (int i = 0; i < 2; i++) begin
      for (int j = 0; j < 2; j++) begin
        C_expected[i][j] = 0;
        for (int k = 0; k < 2; k++) begin
          C_expected[i][j] += A[i][k] * B[k][j];
        end
      end
    end
  endfunction

  function automatic int count_mismatches();
    int errors;
    errors = 0;
    for (int i = 0; i < 2; i++) begin
      for (int j = 0; j < 2; j++) begin
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
    // Example 1: the same signed matrices used in earlier lessons.
    A[0][0] = 1;  A[0][1] = -2;
    A[1][0] = 3;  A[1][1] =  4;
    B[0][0] = -1; B[0][1] =  2;
    B[1][0] =  5; B[1][1] = -3;
    C_actual[0][0] = -11; C_actual[0][1] =  8;
    C_actual[1][0] =  17; C_actual[1][1] = -6;

    calculate_expected();
    if (count_mismatches() != 0)
      $fatal(1, "Example 1 failed");
    $display("PASS example 1: signed matrix multiplication");

    // Example 2: keep A, replace B with the identity matrix.
    // A times identity equals A; supply those answers independently.
    B[0][0] = 1; B[0][1] = 0;
    B[1][0] = 0; B[1][1] = 1;
    C_actual[0][0] = 1; C_actual[0][1] = -2;
    C_actual[1][0] = 3; C_actual[1][1] =  4;

    if ($test$plusargs("INJECT_ERROR"))
      C_actual[0][1] = 2;

    calculate_expected();
    if (count_mismatches() != 0)
      $fatal(1, "Example 2 failed");
    $display("PASS example 2: multiplication by the identity matrix");

    $display("PASS: both examples used the same reference and checker functions.");
    $finish;
  end
endmodule
