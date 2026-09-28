// Lesson 31: visit every sign combination using two nested directed loops.
// A representatives are -3, 0, +3; B representatives are -2, 0, +2.
// Nine fresh items should hit all nine cross bins. These are representative values,
// not an exhaustive test of all signed 8-bit values or complete matrix operations.
// Report A, B, and cross percentages separately, not as one group average.
// These are expectations from the source code, not measured simulation results.
// The monitor broadcasts to the scoreboard and input_coverage independently.
// The initial zero snapshot is included; this is not valid-matrix coverage.
// Real matrix coverage must sample transactions qualified by the actual protocol.
// No coverage percentage is used as a pass criterion. Enable functional coverage
// in a simulator that supports covergroups before running this lesson.
// The fixture and a 200 ns timer run concurrently. Normal completion cancels
// the timer; an unfinished fixture triggers RUN_TIMEOUT under default reporting.
// +HOLD_RESET deliberately leaves reset asserted to exercise the timeout path.
// The 200 ns deadline belongs only to this lesson, not the PDF's DUT specification.
// The scoreboard still compares each received sample immediately in write().
// The test keeps its final count/structure checks in check_phase.
// report_phase prints a teaching PASS/FAIL based on accumulated UVM errors.
// Under default UVM reporting, +INJECT_ERROR records errors and reaches FAIL;
// a nonzero operating-system exit code is not guaranteed. Judge the UVM log.
// Fatal setup errors or a watchdog timeout terminate before report_phase.
// With default reporting there is no LESSON_PASS on these paths.
// The top creates one cfg; the test forwards it to the agent.
// The agent applies cfg.is_active and configures its children with cfg.vif.
// This lesson uses cfg as the sole mode source: no separate is_active DB setting.
// Configure before build and then treat cfg as read-only; it is a shared handle.
// Compile this lesson by itself with UVM enabled; top: sign_combinations_demo.
// None of these six cases has been compiled or simulated with UVM:
// default active, +PASSIVE, +INJECT_ERROR, +PASSIVE +INJECT_ERROR,
// +HOLD_RESET, or +PASSIVE +HOLD_RESET.
// Active: the agent's driver updates the example inputs. Passive: the agent has
// only a monitor, while a separate top-level process supplies the example inputs.
// That top process is a manual teaching source, not a DUT or a DUT output model.
// No DUT is connected. Only ten input snapshots are compared; no complete matrix
// protocol, matrix calculation, or PDF timing verification is implemented.
// Normal schedule without +HOLD_RESET: reset release at 20 ns, nine input updates at 30..110 ns,
// monitor samples at 25..115 ns (ten snapshots), and run ends at 120 ns in either mode.
// check/report then execute without advancing simulation time.
// With +HOLD_RESET, no input samples are collected and timeout is due at 200 ns.
// Expected samples: initial (0,0), followed by all nine pairs with A as outer loop.
// The directed (0,0) item repeats the initial bin: ten snapshots, nine combinations.
// +INJECT_ERROR forces actual b0 to +2 on every driven item; six B checks should fail.
`timescale 1ns/1ps
`include "uvm_macros.svh"

interface systolic_array_if #(
  parameter int DIN_WIDTH = 8,
  parameter int N = 2
)(input logic clk);
  logic rst_n;
  logic signed [DIN_WIDTH-1:0] a_din[0:N-1];
  logic signed [DIN_WIDTH-1:0] b_din[0:N-1];
  logic signed [2*DIN_WIDTH-1:0] c_din[0:N-1];
  logic in_valid;

  // Preserve the output array direction given in the PDF.
  logic signed [2*DIN_WIDTH-1:0] c_dout[N-1:0];
  logic out_valid;
endinterface

package sign_combinations_lesson_pkg;
  import uvm_pkg::*;

  localparam int DIN_WIDTH = 8;
  localparam int N = 2;
  localparam int M = 2;

  // Settings for one agent, not stimulus data and not a UVM component.
  // These fields are not rand; configure them explicitly before run_test().
  class matrix_agent_config extends uvm_object;
    `uvm_object_utils(matrix_agent_config)

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    virtual systolic_array_if vif;

    function new(string name = "matrix_agent_config");
      super.new(name);
    endfunction
  endclass

  // An observed clock sample. No randomization: fields come from the interface.
  class signal_sample extends uvm_sequence_item;
    `uvm_object_utils(signal_sample)

    // Four-state signed fields preserve negative values and any X/Z bits.
    logic signed [DIN_WIDTH-1:0] a0;
    logic signed [DIN_WIDTH-1:0] b0;
    int unsigned sample_index;

    // Factory registration above does not automate these fields' copy/compare.
    function new(string name = "signal_sample");
      super.new(name);
    endfunction
  endclass

  class matrix_item extends uvm_sequence_item;
    `uvm_object_utils(matrix_item)

    rand logic signed [DIN_WIDTH-1:0] A[0:N-1][0:M-1];
    rand logic signed [DIN_WIDTH-1:0] B[0:M-1][0:N-1];

    // Introductory stimulus range; this is not a DUT specification limit.
    constraint small_values {
      foreach (A[i,k]) A[i][k] inside {[-4:4]};
      foreach (B[k,j]) B[k][j] inside {[-4:4]};
    }

    function new(string name = "matrix_item");
      super.new(name);
    endfunction
  endclass

  class matrix_sequence extends uvm_sequence #(matrix_item);
    `uvm_object_utils(matrix_sequence)

    function new(string name = "matrix_sequence");
      super.new(name);
    endfunction

    task body();
      matrix_item item;
      logic signed [DIN_WIDTH-1:0] a_cases[0:2];
      logic signed [DIN_WIDTH-1:0] b_cases[0:2];
      a_cases = '{-8'sd3, 8'sd0, 8'sd3};
      b_cases = '{-8'sd2, 8'sd0, 8'sd2};

      foreach (a_cases[ai]) begin
        foreach (b_cases[bi]) begin
          // A fresh object and complete initialization for every pair.
          item = matrix_item::type_id::create($sformatf("directed_pair_%0d_%0d", ai, bi));
          start_item(item);
          foreach (item.A[i,k]) item.A[i][k] = 0;
          foreach (item.B[k,j]) item.B[k][j] = 0;
          item.A[0][0] = a_cases[ai];
          item.B[0][0] = b_cases[bi];
          // No randomize(); each sign combination is explicitly scheduled.
          // Acknowledge the input access, not a completed matrix result.
          finish_item(item);
        end
      end
    endtask
  endclass

  class matrix_demo_driver extends uvm_driver #(matrix_item);
    `uvm_component_utils(matrix_demo_driver)

    // This type uses the interface defaults: DIN_WIDTH=8 and N=2.
    virtual systolic_array_if vif;
    int unsigned received_count = 0;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(virtual systolic_array_if)::get(
            this, "", "vif", vif))
        `uvm_fatal("NO_VIF", "No virtual interface configured for demo_driver")
    endfunction

    task run_phase(uvm_phase phase);
      matrix_item item;
      wait (vif.rst_n === 1'b1);
      forever begin
        seq_item_port.get_next_item(item);
        @(negedge vif.clk);
        // Only two example elements are driven; this is not matrix delivery.
        vif.a_din[0] = item.A[0][0];
        vif.b_din[0] = item.B[0][0];
        // Optional deliberate corruption exercises the checker failure path.
        // The scoreboard's independent B expectation is never changed by injection.
        if ($test$plusargs("INJECT_ERROR")) begin
          vif.b_din[0] = 8'sd2;
          `uvm_info("INJECT_ERROR", "Deliberately drove b_din[0]=+2", UVM_LOW)
        end

        @(posedge vif.clk);
        received_count++;
        `uvm_info("DRIVER_DEMO",
          $sformatf("Example %0d: a_din[0]=%0d, b_din[0]=%0d",
                    received_count, vif.a_din[0], vif.b_din[0]), UVM_LOW)
        // Acknowledge this access example; no DUT operation has completed.
        seq_item_port.item_done();
      end
    endtask
  endclass

  class matrix_demo_monitor extends uvm_monitor;
    `uvm_component_utils(matrix_demo_monitor)

    uvm_analysis_port #(signal_sample) ap;
    virtual systolic_array_if vif;
    // Counts sampled clock edges, not transactions or matrix operations.
    int unsigned sample_count = 0;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(virtual systolic_array_if)::get(
            this, "", "vif", vif))
        `uvm_fatal("NO_VIF", "No virtual interface configured for demo_monitor")
    endfunction

    task run_phase(uvm_phase phase);
      signal_sample sample;
      wait (vif.rst_n === 1'b1);
      forever begin
        @(posedge vif.clk);
        sample_count++;
        // New object for each edge; reusing its name does not reuse the object.
        sample = signal_sample::type_id::create("sample");
        sample.a0 = vif.a_din[0];
        sample.b0 = vif.b_din[0];
        sample.sample_index = sample_count;

        // These assignments copy values; later bus changes do not update them.
        // Initial zeros and repeated values also become samples. This does not
        // identify valid matrix data or reconstruct a complete matrix.
        // Calls the connected scoreboard's write() without advancing time.
        // Passes this object handle, not a deep copy. Do not modify it afterward.
        ap.write(sample);
      end
    endtask
  endclass

  // Checks this lesson's fixed ten-sample input fixture, not DUT arithmetic.
  class sample_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(sample_scoreboard)

    uvm_analysis_imp #(signal_sample, sample_scoreboard) analysis_in;
    int unsigned received_count = 0;
    int unsigned mismatch_count = 0;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_in = new("analysis_in", this);
    endfunction

    function void write(signal_sample sample);
      logic signed [DIN_WIDTH-1:0] expected_a0;
      logic signed [DIN_WIDTH-1:0] expected_b0;

      if (sample == null) begin
        mismatch_count++;
        `uvm_fatal("NULL_SAMPLE", "Scoreboard got a null sample handle")
        return;
      end
      received_count++;
      // Known answers are independent of the observed fields. This ordering
      // belongs only to this fixed lesson, not to a matrix interface protocol.
      case (received_count)
        // Independent explicit answers, not derived from the stimulus arrays.
        1:  begin expected_a0 = 0;      expected_b0 = 0;       end
        2:  begin expected_a0 = -8'sd3; expected_b0 = -8'sd2;  end
        3:  begin expected_a0 = -8'sd3; expected_b0 = 0;       end
        4:  begin expected_a0 = -8'sd3; expected_b0 = 8'sd2;   end
        5:  begin expected_a0 = 0;      expected_b0 = -8'sd2;  end
        6:  begin expected_a0 = 0;      expected_b0 = 0;       end
        7:  begin expected_a0 = 0;      expected_b0 = 8'sd2;   end
        8:  begin expected_a0 = 8'sd3;  expected_b0 = -8'sd2;  end
        9:  begin expected_a0 = 8'sd3;  expected_b0 = 0;       end
        10: begin expected_a0 = 8'sd3;  expected_b0 = 8'sd2;   end
        default: begin
          mismatch_count++;
          `uvm_error("EXTRA_SAMPLE", "Received more than ten teaching samples")
          return;
        end
      endcase

      // Case inequality also detects X/Z against the known numeric answers.
      if (sample.a0 !== expected_a0) begin
        mismatch_count++;
        `uvm_error("A_MISMATCH",
          $sformatf("Sample %0d: expected a0=%0d, actual a0=%0d",
                    received_count, expected_a0, sample.a0))
      end
      if (sample.b0 !== expected_b0) begin
        mismatch_count++;
        `uvm_error("B_MISMATCH",
          $sformatf("Sample %0d: expected b0=%0d, actual b0=%0d",
                    received_count, expected_b0, sample.b0))
      end
    endfunction
  endclass

  // Records what values were observed; the scoreboard checks their correctness.
  // This is limited to the a0/b0 pair in the fixed DIN_WIDTH=8 teaching fixture.
  class input_coverage extends uvm_component;
    `uvm_component_utils(input_coverage)

    uvm_analysis_imp #(signal_sample, input_coverage) analysis_in;
    logic signed [DIN_WIDTH-1:0] sampled_a0;
    logic signed [DIN_WIDTH-1:0] sampled_b0;
    int unsigned sampled_count = 0;
    int unsigned skipped_unknown_count = 0;

    covergroup sign_pair_cg;
      option.per_instance = 1;
      cp_a_sign: coverpoint sampled_a0 {
        // Each range is ONE bin, not a separate bin for every value.
        bins negative = {[-128:-1]};
        bins zero     = {0};
        bins positive = {[1:127]};
      }
      cp_b_sign: coverpoint sampled_b0 {
        bins negative = {[-128:-1]};
        bins zero     = {0};
        bins positive = {[1:127]};
      }
      // All 3 x 3 combinations of the existing bins are created automatically.
      // Both values must come from the SAME sample() call.
      a_b_sign: cross cp_a_sign, cp_b_sign;
    endgroup

    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_in = new("analysis_in", this);
      sign_pair_cg = new();
    endfunction

    function void write(signal_sample sample);
      if (sample == null) begin
        `uvm_fatal("NULL_COVERAGE_SAMPLE", "Coverage received a null sample")
        return;
      end
      // Only sample when BOTH values are known, so each cross hit is a known pair.
      // The scoreboard separately reports any X/Z mismatch against its answers.
      if ($isunknown({sample.a0, sample.b0})) begin
        skipped_unknown_count++;
        return;
      end
      // Copy both values before sampling; never modify the observation object.
      sampled_a0 = sample.a0;
      sampled_b0 = sample.b0;
      sign_pair_cg.sample();
      sampled_count++;
    endfunction

    function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      // Query the individual coverpoints and cross. Group coverage is an
      // aggregate and must not be reported as this cross's hit percentage.
      `uvm_info("SIGN_PAIR_COVERAGE",
        $sformatf("Teaching snapshots: sampled_pairs=%0d, skipped_unknown=%0d; A sign=%.2f%%, B sign=%.2f%%, A/B sign cross=%.2f%%; not matrix coverage",
                  sampled_count, skipped_unknown_count,
                  sign_pair_cg.cp_a_sign.get_inst_coverage(),
                  sign_pair_cg.cp_b_sign.get_inst_coverage(),
                  sign_pair_cg.a_b_sign.get_inst_coverage()), UVM_NONE)
    endfunction
  endclass

  // A monitor exists in both modes. Only an active agent owns a driver/sequencer.
  // The env-to-scoreboard connection remains the same in either mode.
  class matrix_agent extends uvm_agent;
    `uvm_component_utils(matrix_agent)

    matrix_agent_config cfg;
    uvm_sequencer #(matrix_item) sequencer;
    matrix_demo_driver demo_driver;
    matrix_demo_monitor demo_monitor;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(matrix_agent_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("NO_CFG", "No matrix_agent_config configured for the agent")
      if (cfg == null)
        `uvm_fatal("NULL_CFG", "Agent configuration handle is null")
      if (cfg.vif == null)
        `uvm_fatal("NO_VIF", "Agent configuration has no virtual interface")
      if (cfg.is_active != UVM_ACTIVE && cfg.is_active != UVM_PASSIVE)
        `uvm_fatal("BAD_MODE", "Agent configuration has an invalid mode")

      // This example takes its mode only from cfg. Apply it after super.build_phase
      // to the inherited flag used by get_is_active(); do not redeclare that flag.
      this.is_active = cfg.is_active;
      // Child build phases run after this parent's build_phase returns.
      // Only the agent needs to know its driver's and monitor's instance names.
      uvm_config_db #(virtual systolic_array_if)::set(
        this, "demo_monitor", "vif", cfg.vif);
      demo_monitor = matrix_demo_monitor::type_id::create("demo_monitor", this);
      if (get_is_active() == UVM_ACTIVE) begin
        uvm_config_db #(virtual systolic_array_if)::set(
          this, "demo_driver", "vif", cfg.vif);
        sequencer = uvm_sequencer #(matrix_item)::type_id::create(
                      "sequencer", this);
        demo_driver = matrix_demo_driver::type_id::create("demo_driver", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (get_is_active() == UVM_ACTIVE)
        demo_driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
  endclass

  class matrix_agent_env extends uvm_env;
    `uvm_component_utils(matrix_agent_env)

    matrix_agent agent;
    sample_scoreboard scoreboard;
    input_coverage input_cov;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = matrix_agent::type_id::create("agent", this);
      scoreboard = sample_scoreboard::type_id::create("scoreboard", this);
      input_cov = input_coverage::type_id::create("input_cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      // One observed object is broadcast to two independent, read-only receivers.
      agent.demo_monitor.ap.connect(scoreboard.analysis_in);
      agent.demo_monitor.ap.connect(input_cov.analysis_in);
    endfunction
  endclass

  class matrix_sign_combinations_test extends uvm_test;
    `uvm_component_utils(matrix_sign_combinations_test)

    matrix_agent_env env;
    // The configuration is shared with the agent; never modify it during run.
    matrix_agent_config cfg;

    function new(string name = "matrix_sign_combinations_test",
                 uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(matrix_agent_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("NO_CFG", "No matrix_agent_config configured for the test")
      if (cfg == null)
        `uvm_fatal("NULL_CFG", "Test configuration handle is null")
      if (cfg.vif == null)
        `uvm_fatal("NO_VIF", "Test configuration has no virtual interface")

      // Set the same handle at the agent's scope before its build_phase runs.
      uvm_config_db #(matrix_agent_config)::set(this, "env.agent", "cfg", cfg);
      env = matrix_agent_env::type_id::create("env", this);
    endfunction

    // All components have completed build_phase and connect_phase at this point.
    // Call this once from the test, rather than once from every component.
    function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      // Prints the actual UVM component hierarchy. Ports and sequencer internals
      // may also appear; cfg/sequence/items are not child components.
      // This does not print the HDL module/interface hierarchy or validate data.
      uvm_top.print_topology();
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      // These are the only child processes created by this run_phase.
      // Driver/monitor run_phase processes are launched separately by UVM.
      fork
        begin : fixture_process
          run_fixture();
        end
        begin : watchdog_process
          #200ns;
          `uvm_fatal("RUN_TIMEOUT",
            "Teaching run did not complete within 200 ns; check reset and sequence/driver progress")
        end
      join_any
      // Normal fixture completion at 120 ns cancels the unfinished timer.
      // disable fork affects this process's descendants, not other UVM components.
      // Revisit this scope if other child processes are added to this run_phase.
      disable fork;
      phase.drop_objection(this);
    endtask

    // Finite stimulus-and-observation flow for nine directed input examples.
    // This task owns no objection; run_phase keeps it alive until completion.
    task run_fixture();
      matrix_sequence seq;
      uvm_active_passive_enum requested_mode;
      requested_mode = $test$plusargs("PASSIVE") ? UVM_PASSIVE : UVM_ACTIVE;
      // Catch a configuration mismatch before either source updates the inputs.
      if (env.agent.get_is_active() !== requested_mode)
        `uvm_fatal("MODE_CONFIG", "Agent mode does not match the +PASSIVE selection")

      if (env.agent.get_is_active() == UVM_ACTIVE) begin
        seq = matrix_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
      end
      else begin
        // Passive mode starts no sequence and never dereferences a driver.
        wait (cfg.vif.rst_n === 1'b1);
        repeat (10) @(posedge cfg.vif.clk);
      end

      // At 120 ns, all analysis calls from the 115 ns sample have completed.
      // This is fixture end ordering, not a DUT completion protocol.
      @(negedge cfg.vif.clk);
      // Return only after this fixture's observations have completed.
      // Moving checks to check_phase does not replace this run-time wait.
    endtask

    // UVM calls this after run/extract. It is a function: no clock waits here.
    function void check_phase(uvm_phase phase);
      super.check_phase(phase);
      if (env.agent.get_is_active() == UVM_ACTIVE) begin
        if (env.agent.demo_driver.received_count != 9)
          `uvm_error("TRANSFER_COUNT",
            $sformatf("Expected 9 access examples, received %0d",
                      env.agent.demo_driver.received_count))
      end
      else begin
        if (env.agent.demo_driver != null || env.agent.sequencer != null)
          `uvm_error("PASSIVE_STRUCTURE", "Passive agent must have no driver or sequencer")
      end

      // Includes the initial zero-valued sample; these are not matrix counts.
      if (env.agent.demo_monitor.sample_count != 10 || env.scoreboard.received_count != 10)
        `uvm_error("SAMPLE_COUNT",
          $sformatf("Expected 10 samples; monitor=%0d, scoreboard=%0d",
                    env.agent.demo_monitor.sample_count, env.scoreboard.received_count))
      if (env.scoreboard.mismatch_count != 0)
        `uvm_error("SAMPLE_CHECK_FAILED",
          $sformatf("Teaching input checks found %0d mismatches",
                    env.scoreboard.mismatch_count))
    endfunction

    // All components' check_phase callbacks finish before report_phase starts.
    // One summary in the test also includes errors raised elsewhere in this TB.
    function void report_phase(uvm_phase phase);
      uvm_report_server report_server;
      int error_count;
      int fatal_count;
      super.report_phase(phase);
      report_server = uvm_report_server::get_server();
      error_count = report_server.get_severity_count(UVM_ERROR);
      fatal_count = report_server.get_severity_count(UVM_FATAL);
      if (error_count != 0 || fatal_count != 0) begin
        `uvm_info("LESSON_FAIL",
          $sformatf("Teaching input checks FAILED: UVM_ERROR=%0d, UVM_FATAL=%0d, mismatches=%0d",
                    error_count, fatal_count, env.scoreboard.mismatch_count), UVM_NONE)
      end
      else begin
        `uvm_info("LESSON_PASS",
          "Teaching input checks PASSED: counts and ten samples matched; no DUT results checked.",
          UVM_NONE)
      end
    endfunction
  endclass
endpackage

module sign_combinations_demo;
  import uvm_pkg::*;
  import sign_combinations_lesson_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  // Test, monitor, and optional driver reference this same interface instance.
  systolic_array_if bus(clk);

  initial begin
    bus.rst_n = 0;
    if ($test$plusargs("HOLD_RESET")) begin
      // A deliberate stimulus fault, not a requirement on DUT reset latency.
      $display("HOLD_RESET: leaving reset asserted to exercise the watchdog");
    end
    else begin
      repeat (2) @(negedge clk);
      bus.rst_n = 1;
    end
  end

  // Passive observation still needs an external source of activity.
  // This manual top-level source is separate from the passive agent.
  initial begin
    logic signed [7:0] a_cases[0:2];
    logic signed [7:0] b_cases[0:2];
    a_cases = '{-8'sd3, 8'sd0, 8'sd3};
    b_cases = '{-8'sd2, 8'sd0, 8'sd2};
    if ($test$plusargs("PASSIVE")) begin
      wait (bus.rst_n === 1'b1);
      foreach (a_cases[ai]) begin
        foreach (b_cases[bi]) begin
          @(negedge clk);
          bus.a_din[0] = a_cases[ai];
          bus.b_din[0] = b_cases[bi];
          if ($test$plusargs("INJECT_ERROR"))
            bus.b_din[0] = 8'sd2;
          $display("PASSIVE_SOURCE: ai=%0d, bi=%0d, manual a0=%0d, b0=%0d",
                   ai, bi, bus.a_din[0], bus.b_din[0]);
        end
      end
    end
  end

  initial begin
    matrix_agent_config cfg;

    // Common time-zero initialization precedes any active or passive update.
    // The PDF's valid signals indicate last elements, not ordinary beats.
    bus.in_valid = 0;
    for (int lane = 0; lane < 2; lane++) begin
      bus.a_din[lane] = 0;
      bus.b_din[lane] = 0;
      bus.c_din[lane] = 0;
    end
    // c_dout/out_valid remain undriven because no DUT is instantiated.

    // Fill one configuration object before the UVM hierarchy is built.
    cfg = matrix_agent_config::type_id::create("cfg");
    cfg.vif = bus;
    cfg.is_active = $test$plusargs("PASSIVE") ? UVM_PASSIVE : UVM_ACTIVE;
    // config_db passes the object handle; it does not clone the object.
    // The top only needs the test path, not its driver/monitor hierarchy.
    uvm_config_db #(matrix_agent_config)::set(null, "uvm_test_top", "cfg", cfg);
    run_test("matrix_sign_combinations_test");
  end
endmodule
