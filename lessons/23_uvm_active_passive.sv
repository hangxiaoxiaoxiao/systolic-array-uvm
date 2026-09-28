// Lesson 23: select an active or passive UVM agent at build time.
// Compile this lesson by itself with UVM enabled; top: active_passive_demo.
// None of these four cases has been compiled or simulated with UVM:
// default active, +PASSIVE, +INJECT_ERROR, or +PASSIVE +INJECT_ERROR.
// Active: the agent's driver updates the example inputs. Passive: the agent has
// only a monitor, while a separate top-level process supplies the example inputs.
// That top process is a manual teaching source, not a DUT or a DUT output model.
// No DUT is connected. Only two input snapshots are compared; no complete matrix
// protocol, matrix calculation, or PDF timing verification is implemented.
// Fixed schedule: reset release at 20 ns, input update at 30 ns,
// monitor samples at 25/35 ns, and test completion at 40 ns in either mode.
// Expected samples: (0, 0), then (3, -2). +INJECT_ERROR changes actual b0 to +2.
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

package active_passive_lesson_pkg;
  import uvm_pkg::*;

  localparam int DIN_WIDTH = 8;
  localparam int N = 2;
  localparam int M = 2;

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
      item = matrix_item::type_id::create("directed_item");
      start_item(item);
      // A single known fixture. The item's rand fields are assigned directly.
      foreach (item.A[i,k]) item.A[i][k] = 0;
      foreach (item.B[k,j]) item.B[k][j] = 0;
      item.A[0][0] = 8'sd3;
      item.B[0][0] = -8'sd2;
      // Acknowledges the driver's example access, not a matrix result.
      finish_item(item);
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
        // The scoreboard's independently specified expectation stays at -2.
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

  // Checks this lesson's fixed two-sample input fixture, not DUT arithmetic.
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
        1: begin expected_a0 = 0;      expected_b0 = 0;       end
        2: begin expected_a0 = 8'sd3;  expected_b0 = -8'sd2;  end
        default: begin
          mismatch_count++;
          `uvm_error("EXTRA_SAMPLE", "Received more than two teaching samples")
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

  // A monitor exists in both modes. Only an active agent owns a driver/sequencer.
  // The env-to-scoreboard connection remains the same in either mode.
  class matrix_agent extends uvm_agent;
    `uvm_component_utils(matrix_agent)

    uvm_sequencer #(matrix_item) sequencer;
    matrix_demo_driver demo_driver;
    matrix_demo_monitor demo_monitor;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      // super.build_phase() applies the inherited is_active configuration.
      demo_monitor = matrix_demo_monitor::type_id::create("demo_monitor", this);
      if (get_is_active() == UVM_ACTIVE) begin
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

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = matrix_agent::type_id::create("agent", this);
      scoreboard = sample_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.demo_monitor.ap.connect(scoreboard.analysis_in);
    endfunction
  endclass

  class matrix_active_passive_test extends uvm_test;
    `uvm_component_utils(matrix_active_passive_test)

    matrix_agent_env env;
    // This reference is independent of the optional driver's existence.
    virtual systolic_array_if vif;

    function new(string name = "matrix_active_passive_test",
                 uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(virtual systolic_array_if)::get(
            this, "", "vif", vif))
        `uvm_fatal("NO_VIF", "No virtual interface configured for the test")
      env = matrix_agent_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      matrix_sequence seq;
      uvm_active_passive_enum requested_mode;
      phase.raise_objection(this);
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
        wait (vif.rst_n === 1'b1);
        repeat (2) @(posedge vif.clk);
      end

      // At 40 ns, all analysis calls from the 35 ns sample have completed.
      // This is fixture end ordering, not a DUT completion protocol.
      @(negedge vif.clk);
      if (env.agent.get_is_active() == UVM_ACTIVE) begin
        if (env.agent.demo_driver.received_count != 1)
          `uvm_fatal("TRANSFER_COUNT",
            $sformatf("Expected 1 access example, received %0d",
                      env.agent.demo_driver.received_count))
      end
      else begin
        if (env.agent.demo_driver != null || env.agent.sequencer != null)
          `uvm_fatal("PASSIVE_STRUCTURE", "Passive agent must have no driver or sequencer")
      end

      // Includes the initial zero-valued sample; these are not matrix counts.
      if (env.agent.demo_monitor.sample_count != 2 || env.scoreboard.received_count != 2)
        `uvm_fatal("SAMPLE_COUNT",
          $sformatf("Expected 2 samples; monitor=%0d, scoreboard=%0d",
                    env.agent.demo_monitor.sample_count, env.scoreboard.received_count))
      if (env.scoreboard.mismatch_count != 0)
        `uvm_fatal("SAMPLE_CHECK_FAILED",
          $sformatf("Teaching input checks found %0d mismatches",
                    env.scoreboard.mismatch_count))
      `uvm_info("MODE_SAMPLE_CHECK",
        $sformatf("%s: two teaching input samples matched; no DUT results checked.",
                  requested_mode.name()), UVM_LOW)
      phase.drop_objection(this);
    endtask
  endclass
endpackage

module active_passive_demo;
  import uvm_pkg::*;
  import active_passive_lesson_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  // Test, monitor, and optional driver reference this same interface instance.
  systolic_array_if bus(clk);

  initial begin
    bus.rst_n = 0;
    repeat (2) @(negedge clk);
    bus.rst_n = 1;
  end

  // Passive observation still needs an external source of activity.
  // This manual top-level source is separate from the passive agent.
  initial begin
    if ($test$plusargs("PASSIVE")) begin
      wait (bus.rst_n === 1'b1);
      @(negedge clk);
      bus.a_din[0] = 8'sd3;
      bus.b_din[0] = -8'sd2;
      if ($test$plusargs("INJECT_ERROR"))
        bus.b_din[0] = 8'sd2;
      $display("PASSIVE_SOURCE: manual a0=%0d, b0=%0d",
               bus.a_din[0], bus.b_din[0]);
    end
  end

  initial begin
    // Common time-zero initialization precedes any active or passive update.
    // The PDF's valid signals indicate last elements, not ordinary beats.
    bus.in_valid = 0;
    for (int lane = 0; lane < 2; lane++) begin
      bus.a_din[lane] = 0;
      bus.b_din[lane] = 0;
      bus.c_din[lane] = 0;
    end
    // c_dout/out_valid remain undriven because no DUT is instantiated.

    // Configure the inherited agent mode before run_test builds components.
    // uvm_config_int is an alias for this uvm_bitstream_t specialization.
    uvm_config_db #(uvm_bitstream_t)::set(
      null, "uvm_test_top.env.agent", "is_active",
      $test$plusargs("PASSIVE") ? UVM_PASSIVE : UVM_ACTIVE);
    uvm_config_db #(virtual systolic_array_if)::set(
      null, "uvm_test_top", "vif", bus);
    uvm_config_db #(virtual systolic_array_if)::set(
      null, "uvm_test_top.env.agent.demo_monitor", "vif", bus);
    if (!$test$plusargs("PASSIVE"))
      uvm_config_db #(virtual systolic_array_if)::set(
        null, "uvm_test_top.env.agent.demo_driver", "vif", bus);
    run_test("matrix_active_passive_test");
  end
endmodule
