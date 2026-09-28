// Lesson 1: store two matrices and calculate one output element.
// This is a small arithmetic exercise, not the complete reference model.
module matrix_ref_demo;
  int signed A[0:1][0:1];
  int signed B[0:1][0:1];
  int signed C[0:1][0:1];

  initial begin
    // A = [ 1 -2 ]
    //     [ 3  4 ]
    A[0][0] = 1;  A[0][1] = -2;
    A[1][0] = 3;  A[1][1] =  4;

    // B = [-1  2 ]
    //     [ 5 -3 ]
    B[0][0] = -1; B[0][1] =  2;
    B[1][0] =  5; B[1][1] = -3;

    // First row of A dotted with first column of B.
    // Only C[0][0] is calculated in this lesson.
    C[0][0] = A[0][0] * B[0][0] + A[0][1] * B[1][0];

    $display("C[0][0] = %0d (expected -11)", C[0][0]);
    if (C[0][0] != -11)
      $fatal(1, "Unexpected result");
    $finish;
  end
endmodule
