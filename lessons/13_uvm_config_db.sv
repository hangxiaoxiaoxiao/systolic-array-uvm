// Lesson 13: pass a virtual interface from top to a UVM driver via config_db.
// Compile this lesson by itself with UVM enabled; top: config_db_demo.
// Not yet compiled or simulated with UVM. No DUT is connected.
// This demonstrates interface access, not a complete matrix input protocol.
// No matrix calculation or DUT result checking is performed.
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

package config_db_lesson_pkg;
  import uvm_pkg::*;

  localparam int DIN_WIDTH = 8;
  localparam int N = 2;
  localparam int M = 2;

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
      // "this" plus "" targets this driver's own component path.
      // The type and key "vif" must match the top-level set() call.
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

        // Observe the example inputs after they have had time to settle.
        @(posedge vif.clk);
        received_count++;
        `uvm_info("VIF_DEMO",
          $sformatf("Example %0d: a_din[0]=%0d, b_din[0]=%0d",
                    received_count, vif.a_din[0], vif.b_din[0]), UVM_LOW)
        // Acknowledge this access example; no DUT operation has completed.
        seq_item_port.item_done();
      end
    endtask
  endclass

  class matrix_config_test extends uvm_test;
    `uvm_component_utils(matrix_config_test)

    uvm_sequencer #(matrix_item) sequencer;
    matrix_demo_driver demo_driver;

    function new(string name = "matrix_config_test",
                 uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      sequencer = uvm_sequencer #(matrix_item)::type_id::create(
                    "sequencer", this);
      demo_driver = matrix_demo_driver::type_id::create("demo_driver", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      demo_driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

    task run_phase(uvm_phase phase);
      matrix_sequence seq;
      phase.raise_objection(this);
      seq = matrix_sequence::type_id::create("seq");
      seq.start(sequencer);

      if (demo_driver.received_count != 3)
        `uvm_fatal("TRANSFER_COUNT",
          $sformatf("Expected 3 access examples, received %0d",
                    demo_driver.received_count))
      `uvm_info("VIF_DEMO",
        "Three interface access examples completed; no DUT results checked.",
        UVM_LOW)
      phase.drop_objection(this);
    endtask
  endclass
endpackage

module config_db_demo;
  import uvm_pkg::*;
  import config_db_lesson_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  // Match the default-parameter virtual interface type used in set/get.
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

    // Publish the reference before run_test() starts building components.
    // This is a UVM component path, not the HDL hierarchy path of bus.
    uvm_config_db #(virtual systolic_array_if)::set(
      null, "uvm_test_top.demo_driver", "vif", bus);
    run_test("matrix_config_test");
  end
endmodule
