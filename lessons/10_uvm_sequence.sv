// Lesson 10: send three matrix transactions from a sequence to a driver.
// Compile this lesson by itself with UVM enabled; top: sequence_demo.
// Not yet compiled or simulated. No DUT is connected.
// This demonstrates transaction transfer only, not matrix calculation.
`include "uvm_macros.svh"

package matrix_sequence_lesson_pkg;
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
        // A fresh object keeps each transaction's data independent.
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

    int unsigned received_count = 0;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      matrix_item item;
      forever begin
        seq_item_port.get_next_item(item);
        received_count++;
        `uvm_info("TRANSFER_DEMO",
          $sformatf("Received %0d: A[0][0]=%0d, B[0][0]=%0d",
                    received_count, item.A[0][0], item.B[0][0]), UVM_LOW)
        // No signal driving or reference calculation in this lesson.
        seq_item_port.item_done();
      end
    endtask
  endclass

  class matrix_sequence_test extends uvm_test;
    `uvm_component_utils(matrix_sequence_test)

    uvm_sequencer #(matrix_item) sequencer;
    matrix_demo_driver demo_driver;

    function new(string name = "matrix_sequence_test",
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
          $sformatf("Expected 3 transfers, received %0d",
                    demo_driver.received_count))

      `uvm_info("TRANSFER_DEMO",
        "Three transfers completed; no DUT or matrix results were checked.",
        UVM_LOW)
      phase.drop_objection(this);
    endtask
  endclass
endpackage

module sequence_demo;
  import uvm_pkg::*;
  import matrix_sequence_lesson_pkg::*;

  initial run_test("matrix_sequence_test");
endmodule
