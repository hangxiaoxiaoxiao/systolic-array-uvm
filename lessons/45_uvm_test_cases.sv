// Lesson 45: derive named scenario tests from a shared base test.
// Select one test per simulation using +UVM_TESTNAME=<registered class name>.
// The default is matrix_smoke_test. All four scenarios are uncompiled and unrun.
// The old +INJECT_ERROR / +DROP_LAST_RESULT flags do not select this lesson's case.
// Base build creates cfg, calls virtual configure_scenario(), then publishes cfg.
// Derived tests change only scenario flags; base run/check/report are inherited.
// Test -> env -> source uses exact, relative config_db paths during build_phase.
// config_db transfers the object handle; it does not clone or freeze the object.
// This lesson treats the config as read-only after the test publishes it.
// Only the manual source consumes fault flags; scoreboard expectations stay strict.
// Compile this file alone with UVM enabled; top: matrix_test_cases_demo.
// All outcomes described here are static expectations, not simulation results.
// Fault scenarios must still report checking errors; they are not converted to PASS.
// The env owns component creation/connections; the test selects the scenario.
// The source publishes two directed inputs and independent, hand-filled results.
// It is a teaching source, not a driver, monitor, sequencer, or DUT model.
// Two typed imps dispatch to write_input() and write_output() in the scoreboard.
// Analysis calls are synchronous and pass handles, not deep copies.
// Each published object is fresh and left unchanged after its write() call.
// Both inputs precede any output; FIFO result order is a fixture assumption.
// Independent monitor arrival order and the actual DUT protocol remain unresolved.
// No DUT, interface, clock, latency, or subsystem behavior is implemented.
// All source calls run synchronously at time zero under the test's objection.
// cfg.drop_last_result leaves the second prediction queued for end checks.
// The scoreboard checks general completeness; the test requires two matrices.
// Default UVM errors reach check/report; fatal guards terminate earlier.
// The reused reference function uses $fatal for bad inputs: those stops do not
// increment UVM_FATAL counts and do not reach the normal report_phase summary.
// A mismatch can produce both an immediate error and a check_phase summary error.
// Judge the UVM log; an operating-system nonzero exit is not guaranteed on errors.
// A teaching PASS concerns manual fixtures only, not verification of a DUT.
`timescale 1ns/1ps
`include "uvm_macros.svh"

package matrix_test_cases_lesson_pkg;
  import uvm_pkg::*;

  // Each generated imp's write() calls a different callback on its parent.
  // Declare these once at package scope, before the scoreboard uses the types.
  `uvm_analysis_imp_decl(_input)
  `uvm_analysis_imp_decl(_output)

  localparam int DIN_WIDTH = 8;
  localparam int N = 2;
  localparam int M = 2;
  localparam int PRODUCT_WIDTH = 2 * DIN_WIDTH;
  localparam int ACC_WIDTH = PRODUCT_WIDTH + 1; // Fixed M=2, not arbitrary M.
  localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MIN = -17'sd32768;
  localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MAX =  17'sd32767;

  // Scenario controls for the manual teaching source, not DUT configuration pins.
  class matrix_env_config extends uvm_object;
    `uvm_object_utils(matrix_env_config)

    bit inject_error = 0;
    bit drop_last_result = 0;

    function new(string name = "matrix_env_config");
      super.new(name);
    endfunction
  endclass

  class matrix_item extends uvm_sequence_item;
    `uvm_object_utils(matrix_item)

    rand logic signed [DIN_WIDTH-1:0] A[0:N-1][0:M-1];
    rand logic signed [DIN_WIDTH-1:0] B[0:M-1][0:N-1];

    // A non-static constraint, enabled by default on every fresh object.
    // This is a teaching scenario range, not a DUT legality requirement.
    constraint small_values {
      foreach (A[i,k]) A[i][k] inside {[-4:4]};
      foreach (B[k,j]) B[k][j] inside {[-4:4]};
    }

    function new(string name = "matrix_item");
      super.new(name);
    endfunction
  endclass

  // A reference result record. These fields are calculated/assigned, not random.
  class matrix_prediction extends uvm_object;
    `uvm_object_utils(matrix_prediction)

    int unsigned case_id;
    logic signed [ACC_WIDTH-1:0] C_full[0:N-1][0:N-1];
    logic fits_output[0:N-1][0:N-1];

    // Local metadata helps identify records; it is not a tag returned by a DUT.
    // This object does not store an A/B snapshot or an input item handle.
    function new(string name = "matrix_prediction");
      super.new(name);
    endfunction
  endclass

  // Complete 16-bit result carrier. In this lesson C is filled manually,
  // independently of the reference calculation; it is not sampled from a DUT.
  class matrix_result extends uvm_object;
    `uvm_object_utils(matrix_result)
    logic signed [PRODUCT_WIDTH-1:0] C[0:N-1][0:N-1];

    function new(string name = "matrix_result");
      super.new(name);
    endfunction
  endclass

  // input passes the object HANDLE. This function reads A/B without modifying them.
  // Output arrays contain mathematical predictions, not DUT observations.
  function automatic void calculate_reference(
    input matrix_item item,
    output logic signed [ACC_WIDTH-1:0] C_full[0:N-1][0:N-1],
    output logic fits_output[0:N-1][0:N-1]
  );
    logic signed [DIN_WIDTH-1:0] input_value;
    logic signed [PRODUCT_WIDTH-1:0] product;
    logic signed [ACC_WIDTH-1:0] extended_product;
    logic signed [ACC_WIDTH-1:0] sum;

    if (item == null) begin
      $fatal(1, "NULL_INPUT: reference requires an input item");
      return;
    end

    // Reject unknown inputs before any arithmetic; retain lesson 36's scalar
    // copy for the unknown-value check. No A/B fields are written here.
    foreach (item.A[i,k]) begin
      input_value = item.A[i][k];
      if ($isunknown(input_value))
        $fatal(1, "UNKNOWN_INPUT: A[%0d][%0d] contains X/Z", i, k);
    end
    foreach (item.B[k,j]) begin
      input_value = item.B[k][j];
      if ($isunknown(input_value))
        $fatal(1, "UNKNOWN_INPUT: B[%0d][%0d] contains X/Z", k, j);
    end

    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        sum = '0;
        for (int k = 0; k < M; k++) begin
          // Signed operands and a signed 16-bit destination preserve the product.
          product = item.A[i][k] * item.B[k][j];
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

  class matrix_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(matrix_scoreboard)

    uvm_analysis_imp_input #(matrix_item, matrix_scoreboard) input_in;
    uvm_analysis_imp_output #(matrix_result, matrix_scoreboard) output_in;
    matrix_prediction predictions[$];
    int unsigned enqueued_count = 0;
    int unsigned received_count = 0;
    int unsigned compared_elements = 0;
    int unsigned mismatch_count = 0;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      input_in = new("input_in", this);
      output_in = new("output_in", this);
    endfunction

    // Called through input_in when a complete A/B object is published.
    // The source is a manual fixture, not a monitor of accepted DUT inputs.
    function void write_input(matrix_item item);
      matrix_prediction prediction;
      prediction = matrix_prediction::type_id::create(
                     $sformatf("prediction_%0d", enqueued_count));
      prediction.case_id = enqueued_count;
      calculate_reference(item, prediction.C_full, prediction.fits_output);
      predictions.push_back(prediction);
      enqueued_count++;
      // Fresh, fully calculated prediction; leave its fields read-only afterward.
    endfunction

    // Called through output_in for a complete result. No waits are allowed here.
    function void write_output(matrix_result actual);
      matrix_prediction expected;
      logic signed [PRODUCT_WIDTH-1:0] actual_element;
      logic signed [ACC_WIDTH-1:0] actual_full;

      if (actual == null) begin
        `uvm_fatal("NULL_RESULT", "No result object was supplied")
        return;
      end
      if (predictions.size() == 0) begin
        `uvm_fatal("UNEXPECTED_RESULT", "No prediction is waiting")
        return;
      end
      expected = predictions[0];
      if (expected == null) begin
        `uvm_fatal("NULL_PREDICTION", "Queue contains a null handle")
        return;
      end
      foreach (expected.fits_output[i,j]) begin
        if (expected.fits_output[i][j] !== 1'b1) begin
          `uvm_fatal("REFERENCE_NOT_COMPARABLE",
            $sformatf("Case=%0d C[%0d][%0d]=%0d needs a defined overflow rule; no DUT verdict",
                      expected.case_id, i, j, expected.C_full[i][j]))
          return;
        end
      end

      // No returned transaction ID: FIFO order is assumed for this fixture.
      expected = predictions.pop_front();
      received_count++;
      foreach (actual.C[i,j]) begin
        actual_element = actual.C[i][j];
        actual_full = {actual_element[PRODUCT_WIDTH-1], actual_element};
        compared_elements++;
        if (actual_full !== expected.C_full[i][j]) begin
          mismatch_count++;
          `uvm_error("RESULT_MISMATCH",
            $sformatf("Case=%0d C[%0d][%0d] expected=%0d manual_actual=%0d",
                      expected.case_id, i, j, expected.C_full[i][j], actual_element))
        end
      end
      `uvm_info("RESULT_COMPARED",
        $sformatf("Case=%0d, remaining_predictions=%0d",
                  expected.case_id, predictions.size()), UVM_LOW)
    endfunction

    // General checks: this component does not hard-code two matrices or eight cells.
    function void check_phase(uvm_phase phase);
      super.check_phase(phase);
      if (enqueued_count == 0)
        `uvm_error("NO_INPUTS", "No inputs were registered for comparison")
      if (received_count != enqueued_count)
        `uvm_error("MATRIX_COUNT",
          $sformatf("Registered=%0d, compared results=%0d", enqueued_count, received_count))
      if (predictions.size() != 0)
        `uvm_error("PENDING_RESULTS",
          $sformatf("%0d predictions remain", predictions.size()))
      if (compared_elements != received_count * N * N)
        `uvm_error("ELEMENT_COUNT", "Not all elements of the received matrices were compared")
      if (mismatch_count != 0)
        `uvm_error("RESULT_CHECK_FAILED",
          $sformatf("Found %0d element mismatches", mismatch_count))
    endfunction
  endclass

  // Finite, manual transaction source used only to exercise the checking path.
  // Its two functions are called by the test; this component has no run_phase.
  class matrix_fixture_source extends uvm_component;
    `uvm_component_utils(matrix_fixture_source)

    uvm_analysis_port #(matrix_item) input_ap;
    uvm_analysis_port #(matrix_result) result_ap;
    matrix_env_config cfg;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      input_ap = new("input_ap", this);
      result_ap = new("result_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(matrix_env_config)::get(this, "", "cfg", cfg) || cfg == null) begin
        `uvm_fatal("NO_SOURCE_CFG", "Source requires a non-null matrix_env_config")
        return;
      end
      `uvm_info("FIXTURE_CONFIG",
        $sformatf("inject_error=%0b, drop_last_result=%0b",
                  cfg.inject_error, cfg.drop_last_result), UVM_LOW)
    endfunction

    function void send_inputs();
      matrix_item input0, input1;
      input0 = matrix_item::type_id::create("input0");
      input1 = matrix_item::type_id::create("input1");

      // Direct assignments are not restricted by the randomization constraint.
      input0.A[0][0] =  1; input0.A[0][1] = -2;
      input0.A[1][0] =  3; input0.A[1][1] =  4;
      input0.B[0][0] = -1; input0.B[0][1] =  2;
      input0.B[1][0] =  5; input0.B[1][1] = -3;

      input1.A[0][0] = -2; input1.A[0][1] = 1;
      input1.A[1][0] =  0; input1.A[1][1] = 3;
      input1.B[0][0] =  1; input1.B[0][1] = 0;
      input1.B[1][0] =  0; input1.B[1][1] = 1;

      input_ap.write(input0);
      input_ap.write(input1);
    endfunction

    function void send_results();
      matrix_result result0, result1;
      result0 = matrix_result::type_id::create("result0");
      result1 = matrix_result::type_id::create("result1");

      // Independent hand-calculated fixtures; never copied from the scoreboard.
      result0.C[0][0] = -11; result0.C[0][1] =  8;
      result0.C[1][0] =  17; result0.C[1][1] = -6;
      result1.C[0][0] =  -2; result1.C[0][1] =  1;
      result1.C[1][0] =   0; result1.C[1][1] =  3;

      if (cfg.inject_error) begin
        result0.C[1][0] = 18;
        `uvm_info("INJECT_ERROR", "First manual C[1][0] changed from 17 to 18", UVM_LOW)
      end

      result_ap.write(result0);
      if (cfg.drop_last_result) begin
        `uvm_info("DROP_LAST_RESULT",
          "Deliberately omitted the second manual result; its prediction remains queued",
          UVM_LOW)
      end
      else begin
        result_ap.write(result1);
      end
    endfunction
  endclass

  class matrix_env extends uvm_env;
    `uvm_component_utils(matrix_env)

    matrix_fixture_source source;
    matrix_scoreboard scoreboard;
    matrix_env_config cfg;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(matrix_env_config)::get(this, "", "cfg", cfg) || cfg == null) begin
        `uvm_fatal("NO_ENV_CFG", "Env requires a non-null matrix_env_config")
        return;
      end
      // Forward the same handle only to the source. The scoreboard needs no flags.
      uvm_config_db#(matrix_env_config)::set(this, "source", "cfg", cfg);
      source = matrix_fixture_source::type_id::create("source", this);
      scoreboard = matrix_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      source.input_ap.connect(scoreboard.input_in);
      source.result_ap.connect(scoreboard.output_in);
    endfunction
  endclass

  class matrix_base_test extends uvm_test;
    `uvm_component_utils(matrix_base_test)

    matrix_env env;
    matrix_env_config cfg;

    function new(string name = "matrix_base_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    // Called only after cfg is created, while the test still owns configuration.
    // A derived test can override this hook without duplicating build_phase.
    virtual function void configure_scenario();
      cfg.inject_error = 0;
      cfg.drop_last_result = 0;
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      cfg = matrix_env_config::type_id::create("cfg");
      configure_scenario();
      `uvm_info("SELECTED_SCENARIO",
        $sformatf("test=%s, inject_error=%0b, drop_last_result=%0b",
                  get_type_name(), cfg.inject_error, cfg.drop_last_result), UVM_LOW)
      // From uvm_test_top, "env" names exactly uvm_test_top.env.
      // Finish setting fields before publishing; do not modify them afterward.
      uvm_config_db#(matrix_env_config)::set(this, "env", "cfg", cfg);
      env = matrix_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      // Input analysis writes finish creating predictions before any output.
      env.source.send_inputs();
      if (env.scoreboard.enqueued_count != 2 || env.scoreboard.predictions.size() != 2)
        `uvm_fatal("ENQUEUE_COUNT", "Expected two saved predictions before results")

      // The source reads the flags configured during build_phase.
      env.source.send_results();

      // The finite source has finished. Retain unmatched predictions for checks.
      // This is an end-of-fixture check, not a real DUT timeout rule.
      phase.drop_objection(this);
    endtask

    function void check_phase(uvm_phase phase);
      super.check_phase(phase);
      // Fixed fixture expectations belong in the test, not the reusable scoreboard.
      if (env.scoreboard.enqueued_count != 2 || env.scoreboard.received_count != 2 ||
          env.scoreboard.compared_elements != 8)
        `uvm_error("FIXTURE_COUNT",
          "This fixture requires two inputs, two results, and eight compared elements")
    endfunction

    function void report_phase(uvm_phase phase);
      uvm_report_server report_server;
      int error_count;
      int fatal_count;
      super.report_phase(phase);
      report_server = uvm_report_server::get_server();
      error_count = report_server.get_severity_count(UVM_ERROR);
      fatal_count = report_server.get_severity_count(UVM_FATAL);
      // All check_phase callbacks finish before report_phase begins.
      if (error_count != 0 || fatal_count != 0) begin
        `uvm_info("TEACHING_CHECK_FAIL",
          $sformatf("Manual fixture checks failed: errors=%0d, fatals=%0d, mismatches=%0d",
                    error_count, fatal_count, env.scoreboard.mismatch_count), UVM_NONE)
      end
      else begin
        `uvm_info("TEACHING_CHECK_PASS",
          "Two manual matrices matched queued predictions; no DUT verified.", UVM_NONE)
      end
    endfunction
  endclass
  // No override needed: the base hook selects correct, complete manual results.
  class matrix_smoke_test extends matrix_base_test;
    `uvm_component_utils(matrix_smoke_test)

    function new(string name = "matrix_smoke_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  class matrix_wrong_value_test extends matrix_base_test;
    `uvm_component_utils(matrix_wrong_value_test)

    function new(string name = "matrix_wrong_value_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void configure_scenario();
      super.configure_scenario();
      cfg.inject_error = 1;
    endfunction
  endclass

  class matrix_missing_result_test extends matrix_base_test;
    `uvm_component_utils(matrix_missing_result_test)

    function new(string name = "matrix_missing_result_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void configure_scenario();
      super.configure_scenario();
      cfg.drop_last_result = 1;
    endfunction
  endclass

  class matrix_combined_fault_test extends matrix_base_test;
    `uvm_component_utils(matrix_combined_fault_test)

    function new(string name = "matrix_combined_fault_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void configure_scenario();
      super.configure_scenario();
      cfg.inject_error = 1;
      cfg.drop_last_result = 1;
    endfunction
  endclass
endpackage

module matrix_test_cases_demo;
  import uvm_pkg::*;
  import matrix_test_cases_lesson_pkg::*;
  // UVM's +UVM_TESTNAME selection takes precedence over this default name.
  initial run_test("matrix_smoke_test");
endmodule
