// Lesson 33: disable a named range constraint for a boundary-only random scenario.
// Compile this file alone with UVM enabled; top: boundary_random_demo.
// Not yet compiled or simulated with UVM.
// This is a focused data-generation exercise based on lesson 08.
// It does not extend lesson 32's timed fixture or its hard-coded scoreboard.
// No run_test(), driver, monitor, coverage collector, or DUT is instantiated.
// Successful randomization is not a matrix arithmetic or coverage pass.
`include "uvm_macros.svh"

package boundary_random_lesson_pkg;
  import uvm_pkg::*;

  localparam int DIN_WIDTH = 8;
  localparam int N = 2;
  localparam int M = 2;

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
endpackage

module boundary_random_demo;
  import uvm_pkg::*;
  import boundary_random_lesson_pkg::*;

  initial begin
    matrix_item item;

    // Four independent objects; random values and entire matrices may repeat.
    // This finite example does not guarantee both endpoints at every position
    // or every endpoint combination. No coverage results are collected here.
    for (int trial = 0; trial < 4; trial++) begin
      item = matrix_item::type_id::create($sformatf("boundary_item_%0d", trial));

      // Only disable this named constraint on this object. A/B remain rand.
      // The old range and the inline endpoint set have no common values.
      // Leaving both active would make randomization unsatisfiable.
      item.small_values.constraint_mode(0);

      // The inline constraint applies to this call and does NOT override other
      // enabled constraints. These are the endpoints for fixed DIN_WIDTH=8.
      if (!item.randomize() with {
        foreach (A[i,k]) A[i][k] inside {-128, 127};
        foreach (B[k,j]) B[k][j] inside {-128, 127};
      }) begin
        $fatal(1, "Boundary randomization failed for trial %0d", trial);
      end

      // Print only after successful generation. No expected C is computed.
      $display("Trial %0d: %s", trial, item.get_name());
      $display("A = [%0d, %0d]", item.A[0][0], item.A[0][1]);
      $display("    [%0d, %0d]", item.A[1][0], item.A[1][1]);
      $display("B = [%0d, %0d]", item.B[0][0], item.B[0][1]);
      $display("    [%0d, %0d]", item.B[1][0], item.B[1][1]);

      // small_values stays disabled on this object after randomize().
      // To reuse this object for small values, enable it explicitly with:
      // item.small_values.constraint_mode(1);
      // Enabling affects future randomization, not the values already stored.
      // Here the next iteration creates a new object instead.
    end

    $finish;
  end
endmodule
