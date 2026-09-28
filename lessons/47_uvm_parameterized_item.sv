// Lesson 47: one parameterized UVM input transaction type for A[N][M] and B[M][N].
// Compile this file alone with UVM enabled; top: parameterized_item_demo.
// This lesson has NOT been compiled or simulated with a UVM simulator.
// It creates two differently specialized types and fills their arrays directly.
// No randomize(), UVM phases, reference calculation, driver, monitor, or DUT here.
// Class parameters select the type; they are not mutable run-time config fields.
// Positive DIN_WIDTH, N, and M are required.
`include "uvm_macros.svh"

package parameterized_item_lesson_pkg;
  import uvm_pkg::*;

  class matrix_item #(
    int DIN_WIDTH = 8,
    int N = 2,
    int M = 3
  ) extends uvm_sequence_item;
    // Parameterized factory registration: create by the concrete TYPE below.
    // This macro does not provide a string type name for name-based factory use.
    // It also does not automatically copy, compare, or print the A/B fields.
    `uvm_object_param_utils(matrix_item #(DIN_WIDTH, N, M))

    rand logic signed [DIN_WIDTH-1:0] A[0:N-1][0:M-1];
    rand logic signed [DIN_WIDTH-1:0] B[0:M-1][0:N-1];

    function new(string name = "matrix_item");
      super.new(name);
      if (DIN_WIDTH < 1 || N < 1 || M < 1) begin
        `uvm_fatal("PARAMETER_ERROR", "DIN_WIDTH, N, and M must be positive")
        return;
      end
    endfunction

    // Query the actual array dimensions; do not rely on a generated type-name string.
    function void describe();
      $display("ITEM_SHAPE: name=%s, parameters DIN_WIDTH=%0d N=%0d M=%0d",
               get_name(), DIN_WIDTH, N, M);
      $display("  A: %0d rows x %0d columns, %0d bits/element; A[0][0]=%0d",
               $size(A, 1), $size(A, 2), $bits(A[0][0]), $signed(A[0][0]));
      $display("  B: %0d rows x %0d columns, %0d bits/element; B[0][0]=%0d",
               $size(B, 1), $size(B, 2), $bits(B[0][0]), $signed(B[0][0]));
    endfunction
  endclass
endpackage

module parameterized_item_demo;
  import uvm_pkg::*;
  import parameterized_item_lesson_pkg::*;

  // Parameter order is DIN_WIDTH, N, M. These aliases name different class types.
  typedef matrix_item #(8, 2, 3) item_23_t;
  typedef matrix_item #(4, 3, 2) item_32_t;

  initial begin
    item_23_t item23;
    item_32_t item32;

    // "item23" and "item32" are object instance names, not factory type names.
    item23 = item_23_t::type_id::create("item23");
    item32 = item_32_t::type_id::create("item32");
    if (item23 == null || item32 == null) begin
      $fatal(1, "CREATE_FAILED: expected two transaction objects");
    end

    // Fully assign both objects before inspecting their data. No randomize call.
    foreach (item23.A[i,k]) item23.A[i][k] = -1;
    foreach (item23.B[k,j]) item23.B[k][j] =  2;
    foreach (item32.A[i,k]) item32.A[i][k] =  1;
    foreach (item32.B[k,j]) item32.B[k][j] = -2;

    item23.describe();
    item32.describe();
    $display("PARAMETERIZED_ITEM_DEMO_DONE: shape display only; no computation or DUT verified.");
    $finish;
  end
endmodule
