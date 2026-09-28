// Lesson 3: compare expected results with a sample received matrix.
// There is no DUT here: C_actual is manually supplied demonstration data.
module result_checker;
  int signed A[0:1][0:1];
  int signed B[0:1][0:1];
  int signed C_expected[0:1][0:1];
  int signed C_actual[0:1][0:1];
  int errors;

  initial begin
    A[0][0] = 1;  A[0][1] = -2;
    A[1][0] = 3;  A[1][1] =  4;
    B[0][0] = -1; B[0][1] =  2;
    B[1][0] =  5; B[1][1] = -3;

    // Reference calculation, unchanged from lesson 2.
    for (int i = 0; i < 2; i++) begin
      for (int j = 0; j < 2; j++) begin
        C_expected[i][j] = 0;
        for (int k = 0; k < 2; k++) begin
          C_expected[i][j] += A[i][k] * B[k][j];
        end
      end
    end

    // Stand-in for results that a monitor would collect from a real DUT.
    // Do not generate this data by copying C_expected.
    C_actual[0][0] = -11; C_actual[0][1] =  8;
    C_actual[1][0] =  17; C_actual[1][1] = -6;

    // Run with +INJECT_ERROR to demonstrate detection of a wrong value.
    if ($test$plusargs("INJECT_ERROR"))
      C_actual[1][0] = 18;

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

    if (errors != 0)
      $fatal(1, "FAIL: %0d mismatched element(s)", errors);

    $display("PASS: all four sample results match the reference calculation.");
    $finish;
  end
endmodule
