`ifndef MATRIX_RESULT_SVH
`define MATRIX_RESULT_SVH

// M affects the calculation, but not the result transaction's width or shape.
class matrix_result #(
  int W = 8,
  int N = 2
) extends uvm_object;
  `uvm_object_param_utils(matrix_result #(W, N))

  logic signed [2*W-1:0] C[0:N-1][0:N-1];

  function new(string name = "matrix_result");
    super.new(name);
    if (W < 1 || N < 1) begin
      `uvm_fatal("MATRIX_PARAMETERS", "W and N must be positive")
      return;
    end
  endfunction

  virtual function void do_copy(uvm_object rhs);
    matrix_result #(W, N) source;
    if (!$cast(source, rhs) || source == null) begin
      `uvm_fatal("MATRIX_RESULT_COPY", "Copy requires a non-null matrix_result of the same parameterized type")
      return;
    end
    super.do_copy(rhs);
    foreach (C[i,j]) C[i][j] = source.C[i][j];
  endfunction
endclass

`endif
