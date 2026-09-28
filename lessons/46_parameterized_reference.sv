// Lesson 46: parameterize the complete mathematical sum for A[N][M] * B[M][N].
// Ordinary SystemVerilog: no UVM, DUT, clock, interface, or latency model.
// Supported parameters are positive integers DIN_WIDTH, N, and M.
// ACC_WIDTH = 2*DIN_WIDTH + ceil(log2(M)) is sufficient, not always minimal.
// Output representability is checked separately; no overflow policy is selected.
// Known answers use endpoint identities and shifts, not another matrix multiply.
// +INJECT_UNKNOWN inserts X into A to exercise the reference input guard.
module parameterized_reference_demo #(
  parameter int DIN_WIDTH = 8,
  parameter int N = 2,
  parameter int M = 3
);
  localparam int PRODUCT_WIDTH = 2 * DIN_WIDTH;
  localparam int EXTRA_BITS = (M > 1) ? $clog2(M) : 0;
  localparam int ACC_WIDTH = PRODUCT_WIDTH + EXTRA_BITS;

  localparam logic signed [DIN_WIDTH-1:0] INPUT_MIN =
    {1'b1, {(DIN_WIDTH-1){1'b0}}};
  localparam logic signed [DIN_WIDTH-1:0] INPUT_MAX =
    {1'b0, {(DIN_WIDTH-1){1'b1}}};
  localparam logic signed [PRODUCT_WIDTH-1:0] OUTPUT_MIN_NARROW =
    {1'b1, {(PRODUCT_WIDTH-1){1'b0}}};
  localparam logic signed [PRODUCT_WIDTH-1:0] OUTPUT_MAX_NARROW =
    {1'b0, {(PRODUCT_WIDTH-1){1'b1}}};
  // Widen signed values, rather than zero-extending unsigned concatenations.
  localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MIN = OUTPUT_MIN_NARROW;
  localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MAX = OUTPUT_MAX_NARROW;

  logic signed [DIN_WIDTH-1:0] A[0:N-1][0:M-1];
  logic signed [DIN_WIDTH-1:0] B[0:M-1][0:N-1];
  logic signed [ACC_WIDTH-1:0] C_full[0:N-1][0:N-1];
  logic fits_output[0:N-1][0:N-1];
  logic signed [ACC_WIDTH-1:0] C_known[0:N-1][0:N-1];
  logic fits_known[0:N-1][0:N-1];

  // All arithmetic for known answers also uses parameter-sized vectors.
  logic signed [ACC_WIDTH-1:0] one_full, count_full;
  logic signed [ACC_WIDTH-1:0] positive_product, negative_product;
  logic signed [ACC_WIDTH-1:0] positive_total, negative_total, correction;
  logic signed [PRODUCT_WIDTH-1:0] known_narrow;
  logic signed [ACC_WIDTH-1:0] known_roundtrip;
  int checked_elements = 0;

  function automatic void calculate_reference();
    logic signed [DIN_WIDTH-1:0] input_value;
    logic signed [PRODUCT_WIDTH-1:0] product;
    logic signed [ACC_WIDTH-1:0] extended_product, sum;

    // Retain lesson 36's scalar copy for this Icarus version's $isunknown check.
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
          product = A[i][k] * B[k][j];
          // EXTRA_BITS can be zero for M=1; the product is still present.
          extended_product = {{EXTRA_BITS{product[PRODUCT_WIDTH-1]}}, product};
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
      checked_elements++;
    end
    $display("CASE_PASS: %s, elements=%0d, C[0][0]=%0d, fits_output[0][0]=%b",
             case_name, N*N, C_full[0][0], fits_output[0][0]);
  endtask

  initial begin
    if (DIN_WIDTH < 1 || N < 1 || M < 1)
      $fatal(1, "PARAMETER_ERROR: DIN_WIDTH, N, and M must be positive");
    $display("PARAMETERS: DIN_WIDTH=%0d N=%0d M=%0d PRODUCT_WIDTH=%0d ACC_WIDTH=%0d",
             DIN_WIDTH, N, M, PRODUCT_WIDTH, ACC_WIDTH);

    // For signed W-bit endpoints: min*min = 2^(2W-2),
    // min*max = -2^(2W-2) + 2^(W-1). Shift WIDE vectors, not 32-bit literals.
    one_full = 1;
    count_full = M;
    positive_product = one_full << (2*DIN_WIDTH-2);
    negative_product = -positive_product + (one_full << (DIN_WIDTH-1));
    positive_total = count_full << (2*DIN_WIDTH-2);
    correction = count_full << (DIN_WIDTH-1);
    negative_total = -positive_total + correction;

    // Case 1: zero multiplied by any B yields zero.
    foreach (A[i,k]) A[i][k] = '0;
    foreach (B[k,j]) B[k][j] = INPUT_MAX;
    foreach (C_known[i,j]) begin
      C_known[i][j] = '0;
      fits_known[i][j] = 1'b1;
    end
    if ($test$plusargs("INJECT_UNKNOWN")) A[0][0] = 'x;
    calculate_reference();
    check_reference("zero");

    // Case 2: only the final reduction index contributes on even-numbered rows.
    // Vary output columns as well, so the known answer is not one uniform matrix.
    foreach (A[i,k])
      A[i][k] = ((i % 2 == 0) && (k == M-1)) ? INPUT_MIN : '0;
    foreach (B[k,j]) B[k][j] = (j % 2 == 0) ? INPUT_MAX : INPUT_MIN;
    foreach (C_known[i,j]) begin
      C_known[i][j] = (i % 2 != 0) ? '0 :
                     ((j % 2 == 0) ? negative_product : positive_product);
      fits_known[i][j] = 1'b1; // Any single signed W-bit product fits in 2W bits.
    end
    calculate_reference();
    check_reference("sparse_last_term");

    // Case 3: only C[0][0] accumulates M positive endpoint products.
    // M=2 already exceeds signed 2W bits; other outputs must still fit.
    foreach (A[i,k]) A[i][k] = (i == 0) ? INPUT_MIN : '0;
    foreach (B[k,j]) B[k][j] = (j == 0) ? INPUT_MIN : '0;
    foreach (C_known[i,j]) begin
      C_known[i][j] = ((i == 0) && (j == 0)) ? positive_total : '0;
      fits_known[i][j] = ((i == 0) && (j == 0)) ? (M == 1) : 1'b1;
    end
    calculate_reference();
    check_reference("positive_endpoints");

    // Case 4: all min*max products. Check representability independently by
    // narrowing then sign-extending the KNOWN answer, instead of comparing bounds.
    // This is a checker identity, not a selected DUT truncation behavior.
    known_narrow = negative_total;
    known_roundtrip = known_narrow;
    foreach (A[i,k]) A[i][k] = INPUT_MIN;
    foreach (B[k,j]) B[k][j] = INPUT_MAX;
    foreach (C_known[i,j]) begin
      C_known[i][j] = negative_total;
      fits_known[i][j] = (known_roundtrip == negative_total);
    end
    calculate_reference();
    check_reference("negative_endpoints");

    if (checked_elements != 4*N*N)
      $fatal(1, "CHECK_COUNT: expected %0d checked elements, got %0d", 4*N*N, checked_elements);
    $display("PARAMETERIZED_REFERENCE_PASS: %0d exact sums and range flags matched; no DUT checked.",
             checked_elements);
    $finish;
  end
endmodule
