// Lesson 2: calculate every element of a 2x2 matrix product.
// Small 32-bit integer examples only; DUT widths are introduced later.
module matrix_ref_loops;
  int signed A[0:1][0:1];
  int signed B[0:1][0:1];
  int signed C[0:1][0:1];

  initial begin
    A[0][0] = 1;  A[0][1] = -2;
    A[1][0] = 3;  A[1][1] =  4;

    B[0][0] = -1; B[0][1] =  2;
    B[1][0] =  5; B[1][1] = -3;

    for (int i = 0; i < 2; i++) begin
      for (int j = 0; j < 2; j++) begin
        C[i][j] = 0;
        for (int k = 0; k < 2; k++) begin
          C[i][j] += A[i][k] * B[k][j];
        end
      end
    end

    $display("C = [%0d, %0d]", C[0][0], C[0][1]);
    $display("    [%0d, %0d]", C[1][0], C[1][1]);

    // Independently hand-calculated answers for this example.
    if (C[0][0] !== -11 || C[0][1] !== 8 ||
        C[1][0] !==  17 || C[1][1] !== -6)
      $fatal(1, "Unexpected matrix result");

    $display("PASS: all four elements match the hand-calculated answers.");
    $finish;
  end
endmodule
