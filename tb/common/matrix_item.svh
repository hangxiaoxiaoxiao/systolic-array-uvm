`ifndef MATRIX_ITEM_SVH
`define MATRIX_ITEM_SVH

// Publish only complete, observed matrices. Analysis subscribers must not modify
// the publisher's object. Width and shape are part of the factory type.
class matrix_item #(
  int W = 8,
  int N = 2,
  int M = 3
) extends uvm_sequence_item;
  `uvm_object_param_utils(matrix_item #(W, N, M))

  rand logic signed [W-1:0] A[0:N-1][0:M-1];
  rand logic signed [W-1:0] B[0:M-1][0:N-1];

  // Set to zero before randomize() for the full signed input range. This is a
  // stimulus convenience, not a guarantee that every W/M fits the output width.
  bit use_small_values = 1'b1;
  constraint small_values_c {
    if (use_small_values) {
      foreach (A[i,k]) A[i][k] inside {[-2:2]};
      foreach (B[k,j]) B[k][j] inside {[-2:2]};
    }
  }

  function new(string name = "matrix_item");
    super.new(name);
    if (W < 1 || N < 1 || M < 1) begin
      `uvm_fatal("MATRIX_PARAMETERS", "W, N, and M must be positive")
      return;
    end
  endfunction

  virtual function void do_copy(uvm_object rhs);
    matrix_item #(W, N, M) source;
    if (!$cast(source, rhs) || source == null) begin
      `uvm_fatal("MATRIX_ITEM_COPY", "Copy requires a non-null matrix_item of the same parameterized type")
      return;
    end
    super.do_copy(rhs);
    use_small_values = source.use_small_values;
    foreach (A[i,k]) A[i][k] = source.A[i][k];
    foreach (B[k,j]) B[k][j] = source.B[k][j];
  endfunction
endclass

`endif
