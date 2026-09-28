// Lesson 8: constrained-random input matrices.
// Requires a simulator with the UVM library enabled; top: random_item_demo.
// Not yet compiled or simulated: the online simulator is awaiting login.
// This demonstrates data generation only; no DUT is connected.
`include "uvm_macros.svh"

package random_item_lesson_pkg;
  import uvm_pkg::*;

  localparam int DIN_WIDTH = 8;
  localparam int N = 2;
  localparam int M = 2;

  class matrix_item extends uvm_sequence_item;
    `uvm_object_utils(matrix_item)

    rand logic signed [DIN_WIDTH-1:0] A[0:N-1][0:M-1];
    rand logic signed [DIN_WIDTH-1:0] B[0:M-1][0:N-1];

    // Introductory stimulus range, not a restriction from the DUT spec.
    // With M=2, every exact result is in [-32,32], safely within 16 bits.
    constraint small_values {
      foreach (A[i,k]) A[i][k] inside {[-4:4]};
      foreach (B[k,j]) B[k][j] inside {[-4:4]};
    }

    function new(string name = "matrix_item");
      super.new(name);
    endfunction
  endclass
endpackage

module random_item_demo;
  import uvm_pkg::*;
  import random_item_lesson_pkg::*;

  initial begin
    matrix_item item;

    // Three examples illustrate generation; values may repeat.
    // This is not a claim of functional-coverage completeness.
    for (int trial = 0; trial < 3; trial++) begin
      item = matrix_item::type_id::create($sformatf("item_%0d", trial));
      if (!item.randomize())
        $fatal(1, "Input randomization failed for trial %0d", trial);

      $display("Trial %0d: %s", trial, item.get_name());
      $display("A = [%0d, %0d]", item.A[0][0], item.A[0][1]);
      $display("    [%0d, %0d]", item.A[1][0], item.A[1][1]);
      $display("B = [%0d, %0d]", item.B[0][0], item.B[0][1]);
      $display("    [%0d, %0d]", item.B[1][0], item.B[1][1]);
    end

    $finish;
  end
endmodule
