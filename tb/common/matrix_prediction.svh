`ifndef MATRIX_PREDICTION_SVH
`define MATRIX_PREDICTION_SVH

class matrix_prediction #(
  int W = 8,
  int N = 2,
  int M = 3
) extends uvm_object;
  `uvm_object_param_utils(matrix_prediction #(W, N, M))

  typedef matrix_reference #(W, N, M) reference_t;
  reference_t::sum_array_t C_full;
  reference_t::fits_array_t fits_output;
  longint unsigned case_id = 0;
  bit reference_valid = 1'b0;

  function new(string name = "matrix_prediction");
    super.new(name);
    foreach (C_full[i,j]) begin
      C_full[i][j] = 'x;
      fits_output[i][j] = 1'b0;
    end
    if (W < 1 || N < 1 || M < 1) begin
      `uvm_fatal("MATRIX_PARAMETERS", "W, N, and M must be positive")
      return;
    end
  endfunction

  virtual function void do_copy(uvm_object rhs);
    matrix_prediction #(W, N, M) source;
    if (!$cast(source, rhs) || source == null) begin
      `uvm_fatal("MATRIX_PREDICTION_COPY", "Copy requires a non-null matrix_prediction of the same parameterized type")
      return;
    end
    super.do_copy(rhs);
    case_id = source.case_id;
    reference_valid = source.reference_valid;
    foreach (C_full[i,j]) begin
      C_full[i][j] = source.C_full[i][j];
      fits_output[i][j] = source.fits_output[i][j];
    end
  endfunction
endclass

`endif
