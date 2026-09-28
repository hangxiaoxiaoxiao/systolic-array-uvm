// Lesson 50: compare parameterized manual result objects with queued predictions.
// Compile this file alone with UVM enabled; top: parameterized_matching_demo.
// Default and +INJECT_ERROR have NOT been compiled or simulated with UVM.
// All outcomes described here are static expectations, not simulation results.
// All input predictions precede the manual results; FIFO pairing is a fixture rule.
// C values are independently hand-filled, never copied from predicted C_full.
// The second 8-bit fixture is now A=1, B=3, giving C=9 (not lesson 49's overflow case).
// Reference range guards run before comparison; no output overflow rule is chosen.
// Compare first, then pop: an uncomparable prediction must not be removed.
// Queue storage passes handles; all published input/result/prediction objects stay read-only.
// Positive DIN_WIDTH, N, M required. No UVM phases, interface, clock, monitor, or DUT.
// A teaching PASS concerns three manual results, not hardware verification.
`include "uvm_macros.svh"

package parameterized_matching_lesson_pkg;
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

  // Output element width/shape depends on DIN_WIDTH and N, not the reduction M.
  class matrix_result #(
    int DIN_WIDTH = 8,
    int N = 2
  ) extends uvm_object;
    `uvm_object_param_utils(matrix_result #(DIN_WIDTH, N))

    logic signed [2*DIN_WIDTH-1:0] C[0:N-1][0:N-1];

    function new(string name = "matrix_result");
      super.new(name);
      if (DIN_WIDTH < 1 || N < 1) begin
        `uvm_fatal("PARAMETER_ERROR", "DIN_WIDTH and N must be positive")
        return;
      end
    endfunction
  endclass

  // Stateless comparison helper; the calling fixture owns its queues/counters.
  class matrix_result_checker #(
    int DIN_WIDTH = 8,
    int N = 2,
    int M = 3
  );
    typedef matrix_prediction #(DIN_WIDTH, N, M) prediction_t;
    typedef prediction_t::reference_t reference_t;
    typedef matrix_result #(DIN_WIDTH, N) result_t;
    localparam int PRODUCT_WIDTH = reference_t::PRODUCT_WIDTH;
    localparam int ACC_WIDTH = reference_t::ACC_WIDTH;
    localparam int EXTRA_BITS = reference_t::EXTRA_BITS;

    static function void compare(
      input prediction_t expected,
      input result_t actual,
      output int unsigned mismatches,
      output int unsigned compared_elements
    );
      logic signed [PRODUCT_WIDTH-1:0] actual_element;
      logic signed [ACC_WIDTH-1:0] actual_full;
      mismatches = 0;
      compared_elements = 0;
      if (expected == null || actual == null) begin
        $fatal(1, "NULL_COMPARISON: both prediction and manual result are required");
        return;
      end
      // Check every range flag before comparing any element.
      foreach (expected.fits_output[i,j]) begin
        if (expected.fits_output[i][j] !== 1'b1) begin
          $fatal(1, "REFERENCE_NOT_COMPARABLE: case=%0d C[%0d][%0d]=%0d needs an overflow rule; no DUT verdict",
                 expected.case_id, i, j, expected.C_full[i][j]);
          return;
        end
      end
      foreach (actual.C[i,j]) begin
        actual_element = actual.C[i][j];
        actual_full = {{EXTRA_BITS{actual_element[PRODUCT_WIDTH-1]}}, actual_element};
        compared_elements++;
        // Case inequality also detects X/Z in a manual/observed result.
        if (actual_full !== expected.C_full[i][j]) begin
          mismatches++;
          $display("RESULT_MISMATCH: DIN_WIDTH=%0d N=%0d M=%0d case=%0d C[%0d][%0d] expected=%0d manual_actual=%0d",
                   DIN_WIDTH, N, M, expected.case_id, i, j, expected.C_full[i][j], actual_element);
        end
      end
    endfunction
  endclass
endpackage

module parameterized_matching_demo;
  import uvm_pkg::*;
  import parameterized_matching_lesson_pkg::*;

  typedef matrix_result_checker #(8, 2, 3) checker23_t;
  typedef matrix_result_checker #(4, 3, 2) checker32_t;
  typedef checker23_t::prediction_t prediction23_t;
  typedef checker32_t::prediction_t prediction32_t;
  typedef checker23_t::reference_t ref23_t;
  typedef checker32_t::reference_t ref32_t;
  typedef ref23_t::item_t item23_t;
  typedef ref32_t::item_t item32_t;
  typedef checker23_t::result_t result23_t;
  typedef checker32_t::result_t result32_t;

  initial begin
    prediction23_t predictions23[$];
    prediction32_t predictions32[$];
    result23_t results23[$];
    prediction23_t prediction23;
    prediction32_t prediction32;
    item23_t item23;
    item32_t item32;
    result23_t actual23;
    result32_t actual32;
    int unsigned mismatches, compared_elements;
    int unsigned total_mismatches, total_elements, total_results;

    total_mismatches = 0;
    total_elements = 0;
    total_results = 0;
    for (int case_index = 0; case_index < 2; case_index++) begin
      item23 = item23_t::type_id::create($sformatf("input23_%0d", case_index));
      prediction23 = prediction23_t::type_id::create(
                       $sformatf("prediction23_%0d", case_index));
      if (item23 == null || prediction23 == null)
        $fatal(1, "CREATE_FAILED: expected input and prediction objects");
      if (case_index == 0) begin
        foreach (item23.A[i,k]) item23.A[i][k] = -1;
        foreach (item23.B[k,j]) item23.B[k][j] =  2;
      end
      else begin
        // Three products of 1*3 give 9, representable in signed 16 bits.
        foreach (item23.A[i,k]) item23.A[i][k] = 1;
        foreach (item23.B[k,j]) item23.B[k][j] = 3;
      end
      prediction23.case_id = case_index;
      ref23_t::calculate(item23, prediction23.C_full, prediction23.fits_output);
      predictions23.push_back(prediction23);
    end

    item32 = item32_t::type_id::create("input32_0");
    prediction32 = prediction32_t::type_id::create("prediction32_0");
    if (item32 == null || prediction32 == null)
      $fatal(1, "CREATE_FAILED: expected 4-bit input and prediction objects");
    foreach (item32.A[i,k]) item32.A[i][k] =  1;
    foreach (item32.B[k,j]) item32.B[k][j] = -2;
    prediction32.case_id = 0;
    ref32_t::calculate(item32, prediction32.C_full, prediction32.fits_output);
    predictions32.push_back(prediction32);
    if (predictions23.size() != 2 || predictions32.size() != 1)
      $fatal(1, "QUEUE_COUNT: expected three predictions before any results");

    // Independent hand-calculated outputs. No reads from the reference objects.
    for (int case_index = 0; case_index < 2; case_index++) begin
      actual23 = result23_t::type_id::create($sformatf("actual23_%0d", case_index));
      if (actual23 == null)
        $fatal(1, "CREATE_FAILED: expected a manual result object");
      foreach (actual23.C[i,j])
        actual23.C[i][j] = (case_index == 0) ? -16'sd6 : 16'sd9;
      if (case_index == 0 && $test$plusargs("INJECT_ERROR")) begin
        actual23.C[1][0] = -16'sd5;
        $display("INJECT_ERROR: first manual C[1][0] changed from -6 to -5");
      end
      results23.push_back(actual23);
    end
    actual32 = result32_t::type_id::create("actual32_0");
    if (actual32 == null)
      $fatal(1, "CREATE_FAILED: expected a 4-bit-input manual result object");
    foreach (actual32.C[i,j]) actual32.C[i][j] = -8'sd4;

    foreach (results23[q]) begin
      if (predictions23.size() == 0)
        $fatal(1, "UNEXPECTED_RESULT: no 8-bit-input prediction is waiting");
      checker23_t::compare(predictions23[0], results23[q], mismatches, compared_elements);
      // Numerical mismatches return for aggregation. Fatal range/null guards stop
      // inside compare before this pop; no unsupported result is declared correct.
      prediction23 = predictions23.pop_front();
      total_mismatches += mismatches;
      total_elements += compared_elements;
      total_results++;
      $display("RESULT_COMPARED: DIN_WIDTH=8 case=%0d, elements=%0d mismatches=%0d remaining=%0d",
               prediction23.case_id, compared_elements, mismatches, predictions23.size());
    end

    if (predictions32.size() == 0)
      $fatal(1, "UNEXPECTED_RESULT: no 4-bit-input prediction is waiting");
    checker32_t::compare(predictions32[0], actual32, mismatches, compared_elements);
    prediction32 = predictions32.pop_front();
    total_mismatches += mismatches;
    total_elements += compared_elements;
    total_results++;
    $display("RESULT_COMPARED: DIN_WIDTH=4 case=%0d, elements=%0d mismatches=%0d remaining=%0d",
             prediction32.case_id, compared_elements, mismatches, predictions32.size());

    if (predictions23.size() != 0 || predictions32.size() != 0)
      $fatal(1, "PENDING_RESULTS: predictions remain without a paired result");
    if (total_results != 3 || total_elements != 17)
      $fatal(1, "CHECK_COUNT: expected 3 matrices / 17 elements, got %0d / %0d",
             total_results, total_elements);
    if (total_mismatches != 0)
      $fatal(1, "TEACHING_CHECK_FAILED: found %0d mismatched manual elements", total_mismatches);
    $display("TEACHING_CHECK_PASS: 3 manual matrices / 17 elements matched predictions; no DUT checked.");
    $finish;
  end
endmodule
