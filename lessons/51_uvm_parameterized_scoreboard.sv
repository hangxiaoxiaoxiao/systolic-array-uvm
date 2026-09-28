// Lesson 51: reuse one parameterized UVM scoreboard for two configurations.
// Compile this file alone with UVM enabled; top: parameterized_scoreboard_demo.
// Default and +INJECT_ERROR have NOT been compiled or simulated with UVM.
// The test publishes all inputs before independent manual results, at time zero.
// Analysis writes are synchronous and pass handles; published objects stay read-only.
// Each scoreboard owns its predictions, counters, and typed analysis imps.
// The shared reference/checker helpers retain $fatal guards. Such stops end the
// simulation before normal report_phase and do not increment UVM_FATAL counts.
// Numeric mismatches are promoted to UVM_ERROR by the scoreboard for reporting.
// One mismatch can cause both an immediate error and a check_phase summary error.
// Default UVM_ERROR reporting need not make the operating-system exit code nonzero.
// FIFO pairing is a fixture assumption; independent monitor ordering is unresolved.
// No DUT, env, driver, monitor, interface timing, clock, or subsystem is implemented.
// A teaching PASS concerns three manual matrices only; no overflow rule is selected.
`include "uvm_macros.svh"

package parameterized_scoreboard_lesson_pkg;
  import uvm_pkg::*;

  // Declare the two imp callback suffixes once, before any scoreboard uses them.
  `uvm_analysis_imp_decl(_input)
  `uvm_analysis_imp_decl(_output)

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

  // Stateless comparison helper; each scoreboard owns its queue/counters.
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

  class matrix_scoreboard #(
    int DIN_WIDTH = 8,
    int N = 2,
    int M = 3
  ) extends uvm_scoreboard;
    `uvm_component_param_utils(matrix_scoreboard #(DIN_WIDTH, N, M))

    typedef matrix_scoreboard #(DIN_WIDTH, N, M) this_t;
    typedef matrix_result_checker #(DIN_WIDTH, N, M) checker_t;
    typedef checker_t::prediction_t prediction_t;
    typedef checker_t::reference_t reference_t;
    typedef reference_t::item_t item_t;
    typedef checker_t::result_t result_t;

    uvm_analysis_imp_input #(item_t, this_t) input_in;
    uvm_analysis_imp_output #(result_t, this_t) output_in;
    prediction_t predictions[$];
    int unsigned enqueued_count = 0;
    int unsigned received_count = 0;
    int unsigned compared_elements = 0;
    int unsigned mismatch_count = 0;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      input_in = new("input_in", this);
      output_in = new("output_in", this);
    endfunction

    function void write_input(item_t item);
      prediction_t prediction;
      if (item == null) begin
        `uvm_fatal("NULL_INPUT", "No input object was supplied")
        return;
      end
      prediction = prediction_t::type_id::create($sformatf("prediction_%0d", enqueued_count));
      if (prediction == null) begin
        `uvm_fatal("CREATE_FAILED", "Expected a fresh prediction object")
        return;
      end
      prediction.case_id = enqueued_count;
      reference_t::calculate(item, prediction.C_full, prediction.fits_output);
      predictions.push_back(prediction);
      enqueued_count++;
    endfunction

    function void write_output(result_t actual);
      prediction_t expected;
      int unsigned new_mismatches, new_elements;
      if (actual == null) begin
        `uvm_fatal("NULL_RESULT", "No manual output object was supplied")
        return;
      end
      if (predictions.size() == 0) begin
        `uvm_fatal("UNEXPECTED_RESULT", "No prediction is waiting")
        return;
      end
      // Range/null guards in compare terminate before the pop below.
      checker_t::compare(predictions[0], actual, new_mismatches, new_elements);
      expected = predictions.pop_front();
      received_count++;
      compared_elements += new_elements;
      mismatch_count += new_mismatches;
      if (new_mismatches != 0)
        `uvm_error("MATRIX_MISMATCH",
          $sformatf("Case=%0d has %0d mismatched elements", expected.case_id, new_mismatches))
      `uvm_info("RESULT_COMPARED",
        $sformatf("Case=%0d elements=%0d mismatches=%0d remaining=%0d",
                  expected.case_id, new_elements, new_mismatches, predictions.size()), UVM_LOW)
    endfunction

    // Reusable completeness checks; fixture-specific counts belong in the test.
    function void check_phase(uvm_phase phase);
      super.check_phase(phase);
      if (enqueued_count == 0)
        `uvm_error("NO_INPUTS", "No inputs were registered for comparison")
      if (received_count != enqueued_count)
        `uvm_error("MATRIX_COUNT",
          $sformatf("Registered=%0d, compared results=%0d", enqueued_count, received_count))
      if (predictions.size() != 0)
        `uvm_error("PENDING_RESULTS", $sformatf("%0d predictions remain", predictions.size()))
      if (compared_elements != received_count * N * N)
        `uvm_error("ELEMENT_COUNT", "Not all elements of the received matrices were compared")
      if (mismatch_count != 0)
        `uvm_error("RESULT_CHECK_FAILED", $sformatf("Found %0d element mismatches", mismatch_count))
    endfunction
  endclass

  // A named, non-parameterized test demonstrates two specializations together.
  class parameterized_scoreboard_test extends uvm_test;
    `uvm_component_utils(parameterized_scoreboard_test)

    typedef matrix_scoreboard #(8, 2, 3) scoreboard23_t;
    typedef matrix_scoreboard #(4, 3, 2) scoreboard32_t;
    typedef scoreboard23_t::item_t item23_t;
    typedef scoreboard32_t::item_t item32_t;
    typedef scoreboard23_t::result_t result23_t;
    typedef scoreboard32_t::result_t result32_t;

    scoreboard23_t scoreboard23;
    scoreboard32_t scoreboard32;
    uvm_analysis_port #(item23_t) input23_ap;
    uvm_analysis_port #(item32_t) input32_ap;
    uvm_analysis_port #(result23_t) result23_ap;
    uvm_analysis_port #(result32_t) result32_ap;

    function new(string name = "parameterized_scoreboard_test", uvm_component parent = null);
      super.new(name, parent);
      input23_ap = new("input23_ap", this);
      input32_ap = new("input32_ap", this);
      result23_ap = new("result23_ap", this);
      result32_ap = new("result32_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      scoreboard23 = scoreboard23_t::type_id::create("scoreboard23", this);
      scoreboard32 = scoreboard32_t::type_id::create("scoreboard32", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      input23_ap.connect(scoreboard23.input_in);
      result23_ap.connect(scoreboard23.output_in);
      input32_ap.connect(scoreboard32.input_in);
      result32_ap.connect(scoreboard32.output_in);
    endfunction

    task run_phase(uvm_phase phase);
      item23_t item23;
      item32_t item32;
      result23_t actual23;
      result32_t actual32;
      phase.raise_objection(this);

      for (int case_index = 0; case_index < 2; case_index++) begin
        item23 = item23_t::type_id::create($sformatf("input23_%0d", case_index));
        if (item23 == null)
          `uvm_fatal("CREATE_FAILED", "Expected an 8-bit input object")
        if (case_index == 0) begin
          foreach (item23.A[i,k]) item23.A[i][k] = -1;
          foreach (item23.B[k,j]) item23.B[k][j] =  2;
        end
        else begin
          foreach (item23.A[i,k]) item23.A[i][k] = 1;
          foreach (item23.B[k,j]) item23.B[k][j] = 3;
        end
        input23_ap.write(item23);
      end
      item32 = item32_t::type_id::create("input32_0");
      if (item32 == null)
        `uvm_fatal("CREATE_FAILED", "Expected a 4-bit input object")
      foreach (item32.A[i,k]) item32.A[i][k] =  1;
      foreach (item32.B[k,j]) item32.B[k][j] = -2;
      input32_ap.write(item32);

      if (scoreboard23.enqueued_count != 2 || scoreboard23.predictions.size() != 2 ||
          scoreboard32.enqueued_count != 1 || scoreboard32.predictions.size() != 1)
        `uvm_fatal("ENQUEUE_COUNT", "Expected two plus one predictions before any outputs")

      // Independent hand-filled actual values, never copied from the scoreboards.
      for (int case_index = 0; case_index < 2; case_index++) begin
        actual23 = result23_t::type_id::create($sformatf("actual23_%0d", case_index));
        if (actual23 == null)
          `uvm_fatal("CREATE_FAILED", "Expected an 8-bit-input result object")
        foreach (actual23.C[i,j])
          actual23.C[i][j] = (case_index == 0) ? -16'sd6 : 16'sd9;
        if (case_index == 0 && $test$plusargs("INJECT_ERROR")) begin
          actual23.C[1][0] = -16'sd5;
          `uvm_info("INJECT_ERROR", "First manual C[1][0] changed from -6 to -5", UVM_LOW)
        end
        result23_ap.write(actual23);
      end
      actual32 = result32_t::type_id::create("actual32_0");
      if (actual32 == null)
        `uvm_fatal("CREATE_FAILED", "Expected a 4-bit-input result object")
      foreach (actual32.C[i,j]) actual32.C[i][j] = -8'sd4;
      result32_ap.write(actual32);

      // All synchronous writes have finished; no DUT activity is outstanding.
      phase.drop_objection(this);
    endtask

    function void check_phase(uvm_phase phase);
      super.check_phase(phase);
      if (scoreboard23.enqueued_count != 2 || scoreboard23.received_count != 2 ||
          scoreboard23.compared_elements != 8)
        `uvm_error("FIXTURE23_COUNT", "The 8-bit fixture requires 2 inputs / 2 results / 8 elements")
      if (scoreboard32.enqueued_count != 1 || scoreboard32.received_count != 1 ||
          scoreboard32.compared_elements != 9)
        `uvm_error("FIXTURE32_COUNT", "The 4-bit fixture requires 1 input / 1 result / 9 elements")
    endfunction

    function void report_phase(uvm_phase phase);
      uvm_report_server report_server;
      int error_count, fatal_count;
      int unsigned total_mismatches;
      super.report_phase(phase);
      report_server = uvm_report_server::get_server();
      error_count = report_server.get_severity_count(UVM_ERROR);
      fatal_count = report_server.get_severity_count(UVM_FATAL);
      total_mismatches = scoreboard23.mismatch_count + scoreboard32.mismatch_count;
      // All components have completed check_phase before any report_phase runs.
      if (error_count != 0 || fatal_count != 0) begin
        `uvm_info("TEACHING_CHECK_FAIL",
          $sformatf("Manual fixture checks failed: errors=%0d fatals=%0d mismatches=%0d",
                    error_count, fatal_count, total_mismatches), UVM_NONE)
      end
      else begin
        `uvm_info("TEACHING_CHECK_PASS",
          "Two parameterized scoreboards checked 3 manual matrices / 17 elements; no DUT verified.", UVM_NONE)
      end
    endfunction
  endclass
endpackage

module parameterized_scoreboard_demo;
  import uvm_pkg::*;
  import parameterized_scoreboard_lesson_pkg::*;
  initial run_test("parameterized_scoreboard_test");
endmodule
