// Lesson 16: send monitor samples through a UVM analysis connection.
// Compile this lesson by itself with UVM enabled; top: analysis_port_demo.
// Not yet compiled or simulated with UVM. No DUT is connected.
// There is no complete matrix input protocol or matrix result checking.
// Each object holds two observed input values, not a complete matrix.
// A receiver prints samples; only connection delivery counts are checked.
// No scoreboard, history queue, or matrix arithmetic check is present.
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

package analysis_port_lesson_pkg;
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
      int trial = 0;
      repeat (3) begin
        item = matrix_item::type_id::create($sformatf("item_%0d", trial));
        start_item(item);
        if (!item.randomize())
          `uvm_fatal("RANDOMIZE", "Matrix input randomization failed")
        // Waits for the driver's item_done(), not for a matrix result.
        finish_item(item);
        trial++;
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
        // Calls the connected receiver's write() without advancing time.
        // Passes this object handle, not a deep copy. Do not modify it afterward.
        ap.write(sample);
      end
    endtask
  endclass

  // Teaching receiver: observes samples, with no matrix result checking.
  class sample_receiver extends uvm_component;
    `uvm_component_utils(sample_receiver)

    uvm_analysis_imp #(signal_sample, sample_receiver) analysis_in;
    int unsigned received_count = 0;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_in = new("analysis_in", this);
    endfunction

    // This callback is a function: no clock waits or delays are allowed here.
    // It reads the shared sample object and does not modify or retain it.
    function void write(signal_sample sample);
      if (sample == null)
        `uvm_fatal("NULL_SAMPLE", "Receiver got a null sample handle")
      received_count++;
      `uvm_info("RECEIVER_DEMO",
        $sformatf("Received clock sample %0d: a0=%0d, b0=%0d",
                  sample.sample_index, sample.a0, sample.b0), UVM_LOW)
    endfunction
  endclass

  class matrix_analysis_test extends uvm_test;
    `uvm_component_utils(matrix_analysis_test)

    uvm_sequencer #(matrix_item) sequencer;
    matrix_demo_driver demo_driver;
    matrix_demo_monitor demo_monitor;
    sample_receiver receiver;

    function new(string name = "matrix_analysis_test",
                 uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      sequencer = uvm_sequencer #(matrix_item)::type_id::create(
                    "sequencer", this);
      demo_driver = matrix_demo_driver::type_id::create("demo_driver", this);
      demo_monitor = matrix_demo_monitor::type_id::create("demo_monitor", this);
      receiver = sample_receiver::type_id::create("receiver", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      demo_driver.seq_item_port.connect(sequencer.seq_item_export);
      demo_monitor.ap.connect(receiver.analysis_in);
    endfunction

    task run_phase(uvm_phase phase);
      matrix_sequence seq;
      phase.raise_objection(this);
      seq = matrix_sequence::type_id::create("seq");
      seq.start(sequencer);

      // Teaching-only end ordering: let the final posedge analysis call finish
      // before ending the run phase. This is not a DUT completion protocol.
      @(negedge demo_driver.vif.clk);
      if (demo_driver.received_count != 3)
        `uvm_fatal("TRANSFER_COUNT",
          $sformatf("Expected 3 access examples, received %0d",
                    demo_driver.received_count))
      // Includes initial input zeros; sample count is not a matrix count.
      if (receiver.received_count == 0 ||
          receiver.received_count != demo_monitor.sample_count)
        `uvm_fatal("DELIVERY_COUNT",
          $sformatf("Monitor sampled %0d times; receiver got %0d calls",
                    demo_monitor.sample_count, receiver.received_count))
      `uvm_info("ANALYSIS_DEMO",
        "Sample delivery counts match; no DUT matrix results were checked.",
        UVM_LOW)
      phase.drop_objection(this);
    endtask
  endclass
endpackage

module analysis_port_demo;
  import uvm_pkg::*;
  import analysis_port_lesson_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  // Driver and monitor receive references to this same interface instance.
  systolic_array_if bus(clk);

  initial begin
    bus.rst_n = 0;
    repeat (2) @(negedge clk);
    bus.rst_n = 1;
  end

  initial begin
    // The PDF's valid signals indicate last elements, not ordinary beats.
    // Keep in_valid low: this example submits no complete matrix operation.
    bus.in_valid = 0;
    for (int lane = 0; lane < 2; lane++) begin
      bus.a_din[lane] = 0;
      bus.b_din[lane] = 0;
      bus.c_din[lane] = 0;
    end
    // c_dout/out_valid remain undriven because no DUT is instantiated.

    // Publish both references before run_test() starts building components.
    // These are UVM component paths, not the HDL hierarchy path of bus.
    uvm_config_db #(virtual systolic_array_if)::set(
      null, "uvm_test_top.demo_driver", "vif", bus);
    uvm_config_db #(virtual systolic_array_if)::set(
      null, "uvm_test_top.demo_monitor", "vif", bus);
    run_test("matrix_analysis_test");
  end
endmodule
