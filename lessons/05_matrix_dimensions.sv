// Lesson 5: N x M multiplied by M x N produces N x N.
// This tests the mathematical reference only; there is no DUT or timing model.
// Use small positive dimensions here; arithmetic still uses 32-bit integers.
module matrix_dimensions #(
  parameter int N = 2,
  parameter int M = 3
);
  int signed A[0:N-1][0:M-1];
  int signed B[0:M-1][0:N-1];
  int signed C_expected[0:N-1][0:N-1];
  int signed fixture_answer;
  int errors;

  function automatic void calculate_expected();
    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        C_expected[i][j] = 0;
        for (int k = 0; k < M; k++) begin
          C_expected[i][j] += A[i][k] * B[k][j];
        end
      end
    end
  endfunction

  initial begin
    if (N < 1 || M < 1)
      $fatal(1, "N and M must be positive");

    // A row i contains the same value i+1 in every column.
    for (int i = 0; i < N; i++) begin
      for (int k = 0; k < M; k++) begin
        A[i][k] = i + 1;
      end
    end

    // B column j contains the same value j+1 in every row.
    for (int k = 0; k < M; k++) begin
      for (int j = 0; j < N; j++) begin
        B[k][j] = j + 1;
      end
    end

    calculate_expected();
    $display("A: %0dx%0d, B: %0dx%0d, C: %0dx%0d", N, M, M, N, N, N);

    errors = 0;
    for (int i = 0; i < N; i++) begin
      $write("C row %0d:", i);
      for (int j = 0; j < N; j++) begin
        $write(" %0d", C_expected[i][j]);

        // Only for this simple fixture: all M products are identical.
        // This closed-form check does not repeat the matrix multiply loop.
        fixture_answer = M * (i + 1) * (j + 1);
        if (C_expected[i][j] !== fixture_answer) begin
          errors++;
          $display("\nMISMATCH C[%0d][%0d]: reference=%0d known_answer=%0d",
                   i, j, C_expected[i][j], fixture_answer);
        end
      end
      $write("\n");
    end

    if (errors != 0)
      $fatal(1, "Reference calculation failed for N=%0d M=%0d", N, M);
    $display("PASS: all %0d reference elements match the known-answer fixture.", N*N);
    $finish;
  end
endmodule
