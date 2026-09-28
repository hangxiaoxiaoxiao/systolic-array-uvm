`ifndef MATRIX_REFERENCE_SVH
`define MATRIX_REFERENCE_SVH

// Pure arithmetic namespace: no timing, DUT state, queue, or reference instance.
// Keep the full sum; selecting a truncation/saturation rule requires a spec.
class matrix_reference #(
  int W = 8,
  int N = 2,
  int M = 3
);
  localparam int PRODUCT_WIDTH = 2 * W;
  localparam int EXTRA_BITS = (M > 1) ? $clog2(M) : 0;
  localparam int ACC_WIDTH = PRODUCT_WIDTH + EXTRA_BITS;
  localparam logic signed [PRODUCT_WIDTH-1:0] OUTPUT_MIN_NARROW =
    {1'b1, {(PRODUCT_WIDTH-1){1'b0}}};
  localparam logic signed [PRODUCT_WIDTH-1:0] OUTPUT_MAX_NARROW =
    {1'b0, {(PRODUCT_WIDTH-1){1'b1}}};
  localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MIN = OUTPUT_MIN_NARROW;
  localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MAX = OUTPUT_MAX_NARROW;

  typedef matrix_item #(W, N, M) item_t;
  typedef logic signed [ACC_WIDTH-1:0] sum_array_t[0:N-1][0:N-1];
  typedef logic fits_array_t[0:N-1][0:N-1];

  // Success means valid full-width mathematics, not necessarily representable
  // DUT output. A zero return leaves all values invalid and all range flags low.
  // Explicit returns also protect callers when UVM_FATAL is caught/downgraded.
  static function bit calculate(
    input item_t item,
    output sum_array_t C_full,
    output fits_array_t fits_output
  );
    logic signed [W-1:0] input_value;
    logic signed [PRODUCT_WIDTH-1:0] product;
    logic signed [ACC_WIDTH-1:0] extended_product, sum;

    foreach (C_full[i,j]) begin
      C_full[i][j] = 'x;
      fits_output[i][j] = 1'b0;
    end
    if (W < 1 || N < 1 || M < 1) begin
      `uvm_fatal("MATRIX_PARAMETERS", "W, N, and M must be positive")
      return 1'b0;
    end
    if (item == null) begin
      `uvm_fatal("MATRIX_REFERENCE_NULL", "Reference calculation requires an input matrix")
      return 1'b0;
    end
    // Validate the entire input before writing any usable expected value.
    foreach (item.A[i,k]) begin
      input_value = item.A[i][k];
      if ($isunknown(input_value)) begin
        `uvm_error("MATRIX_REFERENCE_UNKNOWN", $sformatf("A[%0d][%0d] contains X/Z", i, k))
        return 1'b0;
      end
    end
    foreach (item.B[k,j]) begin
      input_value = item.B[k][j];
      if ($isunknown(input_value)) begin
        `uvm_error("MATRIX_REFERENCE_UNKNOWN", $sformatf("B[%0d][%0d] contains X/Z", k, j))
        return 1'b0;
      end
    end

    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        sum = '0;
        for (int k = 0; k < M; k++) begin
          // The assignment context gives the signed multiply 2*W bits.
          product = item.A[i][k] * item.B[k][j];
          extended_product = {{EXTRA_BITS{product[PRODUCT_WIDTH-1]}}, product};
          sum = sum + extended_product;
        end
        C_full[i][j] = sum;
        fits_output[i][j] = (sum >= OUTPUT_MIN) && (sum <= OUTPUT_MAX);
      end
    end
    return 1'b1;
  endfunction
endclass

`endif
