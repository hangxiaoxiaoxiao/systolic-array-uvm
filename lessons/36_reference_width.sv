// Lesson 36: retain the exact reference sum before checking output width.
// Ordinary SystemVerilog; no UVM, DUT, or interface timing is involved.
// Fixed signed 8-bit inputs and M=2 need 17 bits for every exact sum.
// The PDF's output elements are 16 bits in this configuration.
// An out-of-range sum is retained and flagged; no DUT overflow policy is chosen.
// Known answers below are independent, hand-calculated model checks.
// Optional +INJECT_UNKNOWN tests rejection of an X in a reference input.
module reference_width_demo;
  localparam int DIN_WIDTH = 8;
  localparam int N = 2;
  localparam int M = 2;
  localparam int PRODUCT_WIDTH = 2 * DIN_WIDTH;
  localparam int ACC_WIDTH = PRODUCT_WIDTH + 1; // This lesson is fixed to M=2.

  localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MIN = -17'sd32768;
  localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MAX =  17'sd32767;

  logic signed [DIN_WIDTH-1:0] A[0:N-1][0:M-1];
  logic signed [DIN_WIDTH-1:0] B[0:M-1][0:N-1];
  logic signed [ACC_WIDTH-1:0] C_full[0:N-1][0:N-1];
  logic fits_output[0:N-1][0:N-1];

  // These contain independently specified answers, not DUT output.
  logic signed [ACC_WIDTH-1:0] C_known[0:N-1][0:N-1];
  logic fits_known[0:N-1][0:N-1];

  function automatic void calculate_reference();
    logic signed [DIN_WIDTH-1:0] input_value;
    logic signed [PRODUCT_WIDTH-1:0] product;
    logic signed [ACC_WIDTH-1:0] extended_product;
    logic signed [ACC_WIDTH-1:0] sum;

    // Do not allow unknown inputs to turn the range decision into X.
    // Copy to a scalar before $isunknown: the local Icarus build misreported
    // known values when the indexed unpacked-array expression was used directly.
    foreach (A[i,k]) begin
      input_value = A[i][k];
      if ($isunknown(input_value))
        $fatal(1, "UNKNOWN_INPUT: A[%0d][%0d] contains X/Z", i, k);
    end
    foreach (B[k,j]) begin
      input_value = B[k][j];
      if ($isunknown(input_value))
        $fatal(1, "UNKNOWN_INPUT: B[%0d][%0d] contains X/Z", k, j);
    end

    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        sum = '0;
        for (int k = 0; k < M; k++) begin
          // Signed operands and a signed 16-bit destination preserve the product.
          product = A[i][k] * B[k][j];
          // Assign the sign-extended bits to a SIGNED 17-bit variable first.
          // Both operands of the following addition are then signed 17-bit.
          extended_product = {product[PRODUCT_WIDTH-1], product};
          sum = sum + extended_product;
        end
        C_full[i][j] = sum;
        fits_output[i][j] = (sum >= OUTPUT_MIN) && (sum <= OUTPUT_MAX);
      end
    end
  endfunction

  task automatic check_reference(input string case_name);
    foreach (C_full[i,j]) begin
      if (C_full[i][j] !== C_known[i][j] ||
          fits_output[i][j] !== fits_known[i][j])
        $fatal(1, "REFERENCE_MISMATCH: %s C[%0d][%0d] full=%0d known=%0d fits=%b known_fits=%b",
               case_name, i, j, C_full[i][j], C_known[i][j],
               fits_output[i][j], fits_known[i][j]);
      $display("%s C[%0d][%0d]: full=%0d, fits_signed_16=%b",
               case_name, i, j, C_full[i][j], fits_output[i][j]);
    end
  endtask

  initial begin
    // Mixed signs: the familiar hand-calculated 2x2 example.
    A[0][0] = 1;  A[0][1] = -2;
    A[1][0] = 3;  A[1][1] =  4;
    B[0][0] = -1; B[0][1] =  2;
    B[1][0] =  5; B[1][1] = -3;
    C_known[0][0] = -11; C_known[0][1] =  8;
    C_known[1][0] =  17; C_known[1][1] = -6;
    foreach (fits_known[i,j]) fits_known[i][j] = 1'b1;
    if ($test$plusargs("INJECT_UNKNOWN"))
      A[0][0] = 'x;
    calculate_reference();
    check_reference("mixed_signs");

    // Only C[0][0] overflows the 16-bit range: 16384 + 16384 = 32768.
    // The other outputs are zero, so the range flag must be per element.
    foreach (A[i,k]) A[i][k] = '0;
    foreach (B[k,j]) B[k][j] = '0;
    A[0][0] = 8'sh80; A[0][1] = 8'sh80; // signed -128
    B[0][0] = 8'sh80; B[1][0] = 8'sh80;
    foreach (C_known[i,j]) begin
      C_known[i][j] = '0;
      fits_known[i][j] = 1'b1;
    end
    C_known[0][0] = 17'sd32768;
    fits_known[0][0] = 1'b0;
    calculate_reference();
    check_reference("positive_overflow");

    // Two negative products: -16256 + -16256 = -32512, which fits 16 bits.
    foreach (A[i,k]) A[i][k] = 8'sh80;
    foreach (B[k,j]) B[k][j] = 8'sd127;
    foreach (C_known[i,j]) begin
      C_known[i][j] = -17'sd32512;
      fits_known[i][j] = 1'b1;
    end
    calculate_reference();
    check_reference("negative_endpoints");

    $display("REFERENCE_DEMO_PASS: 12 exact sums and range flags matched known answers; no DUT checked.");
    $finish;
  end
endmodule
