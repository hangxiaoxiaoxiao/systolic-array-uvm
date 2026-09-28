// Lesson 49: retain parameterized reference predictions in typed object queues.
// Compile this file alone with UVM enabled; top: parameterized_predictions_demo.
// This example has NOT been compiled or simulated with UVM.
// All expected counts and answers below are static expectations, not run results.
// Each input and prediction is newly created; predictions are filled before enqueue.
// Queues store object handles, not deep copies. Published predictions stay read-only.
// Different parameter specializations use different typed queues in this example.
// case_id is local bookkeeping, not a transaction ID returned by a DUT.
// The example checks stored predictions against 17 independent known answers.
// There is no actual output, matching/pop, scoreboard, UVM phase, clock, or DUT.
// Positive DIN_WIDTH, N, and M are required; no output overflow rule is selected.
`include "uvm_macros.svh"

package parameterized_predictions_lesson_pkg;
  import uvm_pkg::*;

  class matrix_item #(
    int DIN_WIDTH = 8,
    int N = 2,
    int M = 3
  ) extends uvm_sequence_item;
    // Parameterized factory registration: create by the concrete TYPE below.
    // This macro does not provide a string type name for name-based factory use.
    // It also does not automatically copy, compare, or print the A/B fields.
    `uvm_object_param_utils(matrix_item #(DIN_WIDTH, N, M))

    rand logic signed [DIN_WIDTH-1:0] A[0:N-1][0:M-1];
    rand logic signed [DIN_WIDTH-1:0] B[0:M-1][0:N-1];

    function new(string name = "matrix_item");
      super.new(name);
      if (DIN_WIDTH < 1 || N < 1 || M < 1) begin
        `uvm_fatal("PARAMETER_ERROR", "DIN_WIDTH, N, and M must be positive")
        return;
      end
    endfunction

    // Query the actual array dimensions; do not rely on a generated type-name string.
    function void describe();
      $display("ITEM_SHAPE: name=%s, parameters DIN_WIDTH=%0d N=%0d M=%0d",
               get_name(), DIN_WIDTH, N, M);
      $display("  A: %0d rows x %0d columns, %0d bits/element; A[0][0]=%0d",
               $size(A, 1), $size(A, 2), $bits(A[0][0]), $signed(A[0][0]));
      $display("  B: %0d rows x %0d columns, %0d bits/element; B[0][0]=%0d",
               $size(B, 1), $size(B, 2), $bits(B[0][0]), $signed(B[0][0]));
    endfunction
  endclass
  // A parameterized namespace for the pure reference calculation and its types.
  // No object instance or UVM factory registration is needed for this helper.
  class matrix_reference #(
    int DIN_WIDTH = 8,
    int N = 2,
    int M = 3
  );
    localparam int PRODUCT_WIDTH = 2 * DIN_WIDTH;
    localparam int EXTRA_BITS = (M > 1) ? $clog2(M) : 0;
    localparam int ACC_WIDTH = PRODUCT_WIDTH + EXTRA_BITS;
    localparam logic signed [PRODUCT_WIDTH-1:0] OUTPUT_MIN_NARROW =
      {1'b1, {(PRODUCT_WIDTH-1){1'b0}}};
    localparam logic signed [PRODUCT_WIDTH-1:0] OUTPUT_MAX_NARROW =
      {1'b0, {(PRODUCT_WIDTH-1){1'b1}}};
    localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MIN = OUTPUT_MIN_NARROW;
    localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MAX = OUTPUT_MAX_NARROW;

    // Derive input and output types from this helper's same parameter set.
    typedef matrix_item #(DIN_WIDTH, N, M) item_t;
    typedef logic signed [ACC_WIDTH-1:0] sum_array_t[0:N-1][0:N-1];
    typedef logic fits_array_t[0:N-1][0:N-1];

    // static: call through the class type, without creating a reference instance.
    // This method uses only parameters, local constants/types, arguments and locals.
    static function void calculate(
      input item_t item,
      output sum_array_t C_full,
      output fits_array_t fits_output
    );
      logic signed [DIN_WIDTH-1:0] input_value;
      logic signed [PRODUCT_WIDTH-1:0] product;
      logic signed [ACC_WIDTH-1:0] extended_product, sum;

      if (DIN_WIDTH < 1 || N < 1 || M < 1) begin
        $fatal(1, "PARAMETER_ERROR: DIN_WIDTH, N, and M must be positive");
        return;
      end
      if (item == null) begin
        $fatal(1, "NULL_INPUT: reference requires an input item");
        return;
      end
      // Copy to a scalar before $isunknown, retaining lesson 46's guard pattern.
      foreach (item.A[i,k]) begin
        input_value = item.A[i][k];
        if ($isunknown(input_value)) begin
          $fatal(1, "UNKNOWN_INPUT: A[%0d][%0d] contains X/Z", i, k);
          return;
        end
      end
      foreach (item.B[k,j]) begin
        input_value = item.B[k][j];
        if ($isunknown(input_value)) begin
          $fatal(1, "UNKNOWN_INPUT: B[%0d][%0d] contains X/Z", k, j);
          return;
        end
      end

      for (int i = 0; i < N; i++) begin
        for (int j = 0; j < N; j++) begin
          sum = '0;
          for (int k = 0; k < M; k++) begin
            product = item.A[i][k] * item.B[k][j];
            extended_product = {{EXTRA_BITS{product[PRODUCT_WIDTH-1]}}, product};
            sum = sum + extended_product;
          end
          C_full[i][j] = sum;
          fits_output[i][j] = (sum >= OUTPUT_MIN) && (sum <= OUTPUT_MAX);
        end
      end
    endfunction
  endclass

  class matrix_prediction #(
    int DIN_WIDTH = 8,
    int N = 2,
    int M = 3
  ) extends uvm_object;
    `uvm_object_param_utils(matrix_prediction #(DIN_WIDTH, N, M))

    // Reuse the reference helper's exact array types and accumulation width.
    typedef matrix_reference #(DIN_WIDTH, N, M) reference_t;
    reference_t::sum_array_t C_full;
    reference_t::fits_array_t fits_output;
    int unsigned case_id;

    // All fields are calculated/assigned, not rand. No A/B or item handle is saved.
    function new(string name = "matrix_prediction");
      super.new(name);
      if (DIN_WIDTH < 1 || N < 1 || M < 1) begin
        `uvm_fatal("PARAMETER_ERROR", "DIN_WIDTH, N, and M must be positive")
        return;
      end
    endfunction
  endclass
endpackage

module parameterized_predictions_demo;
  import uvm_pkg::*;
  import parameterized_predictions_lesson_pkg::*;

  typedef matrix_prediction #(8, 2, 3) prediction23_t;
  typedef matrix_prediction #(4, 3, 2) prediction32_t;
  typedef prediction23_t::reference_t ref23_t;
  typedef prediction32_t::reference_t ref32_t;
  typedef ref23_t::item_t item23_t;
  typedef ref32_t::item_t item32_t;

  initial begin
    prediction23_t predictions23[$];
    prediction32_t predictions32[$];
    prediction23_t prediction23, saved23;
    prediction32_t prediction32, saved32;
    item23_t item23;
    item32_t item32;
    logic signed [17:0] known23;
    logic known_fit23;
    int checked_elements;

    checked_elements = 0;
    for (int case_index = 0; case_index < 2; case_index++) begin
      item23 = item23_t::type_id::create($sformatf("input23_%0d", case_index));
      prediction23 = prediction23_t::type_id::create(
                       $sformatf("prediction23_%0d", case_index));
      if (item23 == null || prediction23 == null)
        $fatal(1, "CREATE_FAILED: expected fresh 8-bit input/prediction objects");

      if (case_index == 0) begin
        foreach (item23.A[i,k]) item23.A[i][k] = -1;
        foreach (item23.B[k,j]) item23.B[k][j] =  2;
      end
      else begin
        foreach (item23.A[i,k]) item23.A[i][k] = 8'sh80;
        foreach (item23.B[k,j]) item23.B[k][j] = 8'sh80;
      end
      prediction23.case_id = case_index;
      ref23_t::calculate(item23, prediction23.C_full, prediction23.fits_output);
      predictions23.push_back(prediction23);
      // The next iteration changes this local handle to a NEW object.
      // The queue still refers to the previous fully calculated object.
    end

    item32 = item32_t::type_id::create("input32_0");
    prediction32 = prediction32_t::type_id::create("prediction32_0");
    if (item32 == null || prediction32 == null)
      $fatal(1, "CREATE_FAILED: expected fresh 4-bit input/prediction objects");
    foreach (item32.A[i,k]) item32.A[i][k] =  1;
    foreach (item32.B[k,j]) item32.B[k][j] = -2;
    prediction32.case_id = 0;
    ref32_t::calculate(item32, prediction32.C_full, prediction32.fits_output);
    predictions32.push_back(prediction32);

    // Inspect only AFTER all predictions were created, so the first result must
    // have survived later calculations. No prediction is removed or modified.
    if (predictions23.size() != 2 || predictions32.size() != 1)
      $fatal(1, "QUEUE_COUNT: expected two 8-bit and one 4-bit predictions");

    foreach (predictions23[q]) begin
      saved23 = predictions23[q];
      if (saved23 == null)
        $fatal(1, "NULL_PREDICTION: 8-bit queue entry %0d is null", q);
      if (saved23.case_id != q)
        $fatal(1, "CASE_ORDER: 8-bit entry %0d has case_id=%0d", q, saved23.case_id);
      // Oracle is fixed by intended queue position, not taken from saved metadata.
      known23 = (q == 0) ? -18'sd6 : 18'sd49152;
      known_fit23 = (q == 0) ? 1'b1 : 1'b0;
      foreach (saved23.C_full[i,j]) begin
        if (saved23.C_full[i][j] !== known23 || saved23.fits_output[i][j] !== known_fit23)
          $fatal(1, "PREDICTION_MISMATCH: 8-bit entry %0d C[%0d][%0d]=%0d fits=%b, known=%0d/%b",
                 q, i, j, saved23.C_full[i][j], saved23.fits_output[i][j], known23, known_fit23);
        checked_elements++;
      end
      $display("SAVED_PREDICTION: DIN_WIDTH=8 N=2 M=3, case_id=%0d, C00=%0d, fits00=%b",
               saved23.case_id, saved23.C_full[0][0], saved23.fits_output[0][0]);
    end

    saved32 = predictions32[0];
    if (saved32 == null)
      $fatal(1, "NULL_PREDICTION: 4-bit queue entry is null");
    if (saved32.case_id != 0)
      $fatal(1, "CASE_ORDER: expected case_id=0 for the 4-bit queue");
    foreach (saved32.C_full[i,j]) begin
      if (saved32.C_full[i][j] !== -9'sd4 || saved32.fits_output[i][j] !== 1'b1)
        $fatal(1, "PREDICTION_MISMATCH: 4-bit C[%0d][%0d]=%0d fits=%b, known=-4/1",
               i, j, saved32.C_full[i][j], saved32.fits_output[i][j]);
      checked_elements++;
    end
    $display("SAVED_PREDICTION: DIN_WIDTH=4 N=3 M=2, case_id=%0d, C00=%0d, fits00=%b",
             saved32.case_id, saved32.C_full[0][0], saved32.fits_output[0][0]);

    if (checked_elements != 17)
      $fatal(1, "CHECK_COUNT: expected 17 reference elements, got %0d", checked_elements);
    $display("PREDICTION_STORAGE_PASS: 3 saved predictions matched 17 reference sums/flags; no DUT checked.");
    $finish;
  end
endmodule
