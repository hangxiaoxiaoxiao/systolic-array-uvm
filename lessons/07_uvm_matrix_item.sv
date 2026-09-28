// Lesson 7: one transaction object holds the inputs for one matrix multiply.
// Requires a simulator with the UVM library enabled; top: matrix_item_demo.
// This example has not yet been compiled or run with a UVM simulator.
// It creates an object only: no DUT, driver, or UVM phase execution yet.
`include "uvm_macros.svh"

package matrix_item_lesson_pkg;
  import uvm_pkg::*;

  // Fixed configuration for this introductory object example.
  localparam int DIN_WIDTH = 8;
  localparam int N = 2;
  localparam int M = 2;

  class matrix_item extends uvm_sequence_item;
    // Registers this type with the UVM factory.
    // This macro alone does not copy, compare, or print the A/B fields.
    `uvm_object_utils(matrix_item)

    logic signed [DIN_WIDTH-1:0] A[0:N-1][0:M-1];
    logic signed [DIN_WIDTH-1:0] B[0:M-1][0:N-1];

    function new(string name = "matrix_item");
      super.new(name);
    endfunction
  endclass
endpackage

module matrix_item_demo;
  import uvm_pkg::*;
  import matrix_item_lesson_pkg::*;

  initial begin
    matrix_item item;
    item = matrix_item::type_id::create("item");

    item.A[0][0] = 1;  item.A[0][1] = -2;
    item.A[1][0] = 3;  item.A[1][1] =  4;
    item.B[0][0] = -1; item.B[0][1] =  2;
    item.B[1][0] =  5; item.B[1][1] = -3;

    $display("Object: %s, type: %s", item.get_name(), item.get_type_name());
    $display("A = [%0d, %0d]", item.A[0][0], item.A[0][1]);
    $display("    [%0d, %0d]", item.A[1][0], item.A[1][1]);
    $display("B = [%0d, %0d]", item.B[0][0], item.B[0][1]);
    $display("    [%0d, %0d]", item.B[1][0], item.B[1][1]);
    $finish;
  end
endmodule
