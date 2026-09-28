`ifndef MATRIX_CORE_TEST_SVH
`define MATRIX_CORE_TEST_SVH

// Each run exercises two parameter specializations of the same shared core.
// Expected results are independent literals, never copied from the predictor.
class matrix_core_smoke_test extends uvm_test;
  `uvm_component_utils(matrix_core_smoke_test)
  typedef matrix_item #(8, 2, 3) input_a_t;
  typedef matrix_item #(4, 3, 2) input_b_t;
  typedef matrix_result #(8, 2) result_a_t;
  typedef matrix_result #(4, 3) result_b_t;
  typedef matrix_scoreboard #(8, 2, 3) scoreboard_a_t;
  typedef matrix_scoreboard #(4, 3, 2) scoreboard_b_t;

  scoreboard_a_t scoreboard_a;
  scoreboard_b_t scoreboard_b;
  uvm_analysis_port #(input_a_t) input_a_ap;
  uvm_analysis_port #(input_b_t) input_b_ap;
  uvm_analysis_port #(result_a_t) output_a_ap;
  uvm_analysis_port #(result_b_t) output_b_ap;

  bit outputs_first = 0;
  bit mutate_after_publish = 0;
  bit inject_wrong_result = 0;
  bit omit_second_result = 0;
  bit publications_done = 0;

  function new(string name = "matrix_core_smoke_test", uvm_component parent = null);
    super.new(name, parent);
    input_a_ap = new("input_a_ap", this);
    input_b_ap = new("input_b_ap", this);
    output_a_ap = new("output_a_ap", this);
    output_b_ap = new("output_b_ap", this);
  endfunction

  virtual function void configure_scenario();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    configure_scenario();
    scoreboard_a = scoreboard_a_t::type_id::create("scoreboard_a", this);
    scoreboard_b = scoreboard_b_t::type_id::create("scoreboard_b", this);
    if (scoreboard_a == null || scoreboard_b == null)
      `uvm_fatal("CORE_CREATE_FAILED", "Could not create core scoreboards")
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    input_a_ap.connect(scoreboard_a.input_in);
    output_a_ap.connect(scoreboard_a.output_in);
    input_b_ap.connect(scoreboard_b.input_in);
    output_b_ap.connect(scoreboard_b.output_in);
  endfunction

  function void publish_inputs(input bit group_a = 1'b1, input bit group_b = 1'b1);
    input_a_t first, second;
    input_b_t alternate;
    if (group_a) begin
      first = input_a_t::type_id::create("first_input");
      second = input_a_t::type_id::create("second_input");
      if (first == null || second == null) begin
        `uvm_fatal("CORE_CREATE_FAILED", "Could not create group A input fixtures")
        return;
      end
      first.A[0][0] = 1; first.A[0][1] = -2; first.A[0][2] = 3;
      first.A[1][0] = 4; first.A[1][1] = 5; first.A[1][2] = -6;
      first.B[0][0] = 7; first.B[0][1] = 8;
      first.B[1][0] = -9; first.B[1][1] = 10;
      first.B[2][0] = 11; first.B[2][1] = -12;

      second.A[0][0] = 2; second.A[0][1] = 3; second.A[0][2] = 4;
      second.A[1][0] = -1; second.A[1][1] = 0; second.A[1][2] = 5;
      foreach (second.B[k,j]) second.B[k][j] = (k == j) ? 1 : 0;
      input_a_ap.write(first);
      input_a_ap.write(second);
      if (mutate_after_publish) begin
        // The snapshot scenario has not published group A outputs yet.
        foreach (first.A[i,k]) first.A[i][k] = 0;
        foreach (first.B[k,j]) first.B[k][j] = 0;
        foreach (second.A[i,k]) second.A[i][k] = 0;
        foreach (second.B[k,j]) second.B[k][j] = 0;
      end
    end
    if (group_b) begin
      alternate = input_b_t::type_id::create("alternate_input");
      if (alternate == null) begin
        `uvm_fatal("CORE_CREATE_FAILED", "Could not create group B input fixture")
        return;
      end
      foreach (alternate.A[i,k]) alternate.A[i][k] = -1;
      foreach (alternate.B[k,j]) alternate.B[k][j] = 2;
      input_b_ap.write(alternate);
      if (mutate_after_publish) begin
        foreach (alternate.A[i,k]) alternate.A[i][k] = 0;
        foreach (alternate.B[k,j]) alternate.B[k][j] = 0;
      end
    end
  endfunction

  function void publish_outputs(input bit group_a = 1'b1, input bit group_b = 1'b1);
    result_a_t first, second;
    result_b_t alternate;
    if (group_a) begin
      first = result_a_t::type_id::create("first_result");
      second = result_a_t::type_id::create("second_result");
      if (first == null || second == null) begin
        `uvm_fatal("CORE_CREATE_FAILED", "Could not create group A output fixtures")
        return;
      end
      first.C[0][0] = 16'sd58; first.C[0][1] = -16'sd48;
      first.C[1][0] = -16'sd83; first.C[1][1] = 16'sd154;
      second.C[0][0] = 16'sd2; second.C[0][1] = 16'sd3;
      second.C[1][0] = -16'sd1; second.C[1][1] = 16'sd0;
      if (inject_wrong_result) first.C[1][0] = -16'sd82;
      output_a_ap.write(first);
      if (!omit_second_result) output_a_ap.write(second);
      if (mutate_after_publish) begin
        foreach (first.C[i,j]) first.C[i][j] = 0;
        foreach (second.C[i,j]) second.C[i][j] = 0;
      end
    end
    if (group_b) begin
      alternate = result_b_t::type_id::create("alternate_result");
      if (alternate == null) begin
        `uvm_fatal("CORE_CREATE_FAILED", "Could not create group B output fixture")
        return;
      end
      foreach (alternate.C[i,j]) alternate.C[i][j] = -8'sd4;
      output_b_ap.write(alternate);
      if (mutate_after_publish) begin
        // The snapshot scenario has not published the group B input yet.
        foreach (alternate.C[i,j]) alternate.C[i][j] = 0;
      end
    end
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    if (mutate_after_publish) begin
      // Exercise both ownership directions before their counterparts arrive.
      publish_inputs(1'b1, 1'b0);  // A predictions queued; source A/B overwritten.
      publish_outputs(1'b0, 1'b1); // B actual queued; source C overwritten.
      if (scoreboard_a.predictions.size() != 2 || scoreboard_a.actual_results.size() != 0 ||
          scoreboard_b.predictions.size() != 0 || scoreboard_b.actual_results.size() != 1 ||
          scoreboard_a.compared_count != 0 || scoreboard_b.compared_count != 0)
        `uvm_error("CORE_SNAPSHOT_SETUP", "Both snapshot directions must remain queued before their counterparts arrive")
      publish_outputs(1'b1, 1'b0);
      publish_inputs(1'b0, 1'b1);
    end else if (outputs_first) begin
      publish_outputs();
      // These are software callback-order tests, not early hardware responses.
      if (scoreboard_a.compared_count != 0 || scoreboard_b.compared_count != 0)
        `uvm_error("CORE_EARLY_COMPARE", "No input exists yet; results must remain queued")
      publish_inputs();
    end else begin
      publish_inputs();
      publish_outputs();
    end
    publications_done = 1;
    `uvm_info("CORE_FIXTURE_DONE", "all scheduled publications completed", UVM_NONE)
    phase.drop_objection(this);
  endtask

  function void check_phase(uvm_phase phase);
    int expected_a_results;
    super.check_phase(phase);
    expected_a_results = omit_second_result ? 1 : 2;
    if (!publications_done)
      `uvm_error("CORE_FIXTURE_INCOMPLETE", "Stimulus did not complete")
    if (scoreboard_a.input_count != 2 || scoreboard_b.input_count != 1 ||
        scoreboard_a.output_count != expected_a_results || scoreboard_b.output_count != 1 ||
        scoreboard_a.compared_count != expected_a_results || scoreboard_b.compared_count != 1 ||
        scoreboard_a.compared_elements != expected_a_results*4 || scoreboard_b.compared_elements != 9)
      `uvm_error("CORE_FIXTURE_COUNTS", "Expected fixture counts were not observed")
    if (scoreboard_a.mismatch_count != (inject_wrong_result ? 1 : 0) ||
        scoreboard_b.mismatch_count != 0)
      `uvm_error("CORE_FIXTURE_MISMATCHES", "Wrong number of injected/observed mismatches")
    if (scoreboard_a.predictions.size() != (omit_second_result ? 1 : 0) ||
        scoreboard_b.predictions.size() != 0 || scoreboard_a.actual_results.size() != 0 ||
        scoreboard_b.actual_results.size() != 0)
      `uvm_error("CORE_FIXTURE_PENDING", "Unexpected pending queues")
    if (!omit_second_result && (!scoreboard_a.is_drained() || !scoreboard_b.is_drained()))
      `uvm_error("CORE_NOT_DRAINED", "Expected both queues to have been processed")
  endfunction

  function void report_phase(uvm_phase phase);
    uvm_report_server server;
    super.report_phase(phase);
    server = uvm_report_server::get_server();
    `uvm_info("CORE_COUNTS", $sformatf(
      "inputs=%0d outputs=%0d compared=%0d elements=%0d mismatches=%0d pending_predictions=%0d pending_actuals=%0d",
      scoreboard_a.input_count + scoreboard_b.input_count,
      scoreboard_a.output_count + scoreboard_b.output_count,
      scoreboard_a.compared_count + scoreboard_b.compared_count,
      scoreboard_a.compared_elements + scoreboard_b.compared_elements,
      scoreboard_a.mismatch_count + scoreboard_b.mismatch_count,
      scoreboard_a.predictions.size() + scoreboard_b.predictions.size(),
      scoreboard_a.actual_results.size() + scoreboard_b.actual_results.size()), UVM_NONE)
    if (server.get_severity_count(UVM_ERROR) != 0 || server.get_severity_count(UVM_FATAL) != 0)
      `uvm_info("CORE_SELFTEST_FAIL", "Core fixture reported errors; inspect report IDs and counts", UVM_NONE)
    else
      `uvm_info("CORE_SELFTEST_PASS", "Three independent result fixtures matched; no DUT verified", UVM_NONE)
  endfunction
endclass

class matrix_core_wrong_result_test extends matrix_core_smoke_test;
  `uvm_component_utils(matrix_core_wrong_result_test)
  function new(string name = "matrix_core_wrong_result_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  function void configure_scenario();
    inject_wrong_result = 1;
  endfunction
endclass

class matrix_core_missing_result_test extends matrix_core_smoke_test;
  `uvm_component_utils(matrix_core_missing_result_test)
  function new(string name = "matrix_core_missing_result_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  function void configure_scenario();
    omit_second_result = 1;
  endfunction
endclass

class matrix_core_output_first_test extends matrix_core_smoke_test;
  `uvm_component_utils(matrix_core_output_first_test)
  function new(string name = "matrix_core_output_first_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  function void configure_scenario();
    outputs_first = 1;
  endfunction
endclass

class matrix_core_snapshot_test extends matrix_core_smoke_test;
  `uvm_component_utils(matrix_core_snapshot_test)
  function new(string name = "matrix_core_snapshot_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  function void configure_scenario();
    mutate_after_publish = 1;
  endfunction
endclass

`endif
