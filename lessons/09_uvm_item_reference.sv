// Lesson 9: pass a randomized input transaction to a reference function.
// Requires a simulator with the UVM library enabled; top: item_reference_demo.
// Not yet compiled or simulated in a UVM environment.
// Printed results are predictions only; no DUT or actual-result comparison.
`include "uvm_macros.svh"

package item_reference_lesson_pkg;
  import uvm_pkg::*;

  localparam int DIN_WIDTH = 8;
  localparam int N = 2;
  localparam int M = 2;

  class matrix_item extends uvm_sequence_item;
    `uvm_object_utils(matrix_item)

    rand logic signed [DIN_WIDTH-1:0] A[0:N-1][0:M-1];
    rand logic signed [DIN_WIDTH-1:0] B[0:M-1][0:N-1];

    constraint small_values {
      foreach (A[i,k]) A[i][k] inside {[-4:4]};
      foreach (B[k,j]) B[k][j] inside {[-4:4]};
    }

    function new(string name = "matrix_item");
      super.new(name);
    endfunction
  endclass

  // Reusable mathematical calculation with explicit input and output arguments.
  // The input is an object handle. Read its fields without modifying them.
  function automatic void calculate_expected(
    input matrix_item item,
    output logic signed [2*DIN_WIDTH-1:0] C_expected[0:N-1][0:N-1]
  );
    int signed product;
    int signed sum;

    if (item == null)
      $fatal(1, "Reference calculation requires an input transaction");

    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        sum = 0;
        for (int k = 0; k < M; k++) begin
          product = item.A[i][k] * item.B[k][j];
          sum += product;
        end

        // Fixed 8-bit-input lesson: 32-bit accumulation is sufficient.
        // Do not select a DUT overflow policy that the PDF has not specified.
        if (sum < -32768 || sum > 32767)
          $fatal(1, "Reference sum exceeds the lesson's 16-bit result range");
        C_expected[i][j] = sum;
      end
    end
  endfunction
endpackage

module item_reference_demo;
  import uvm_pkg::*;
  import item_reference_lesson_pkg::*;

  logic signed [2*DIN_WIDTH-1:0] C_expected[0:N-1][0:N-1];

  initial begin
    matrix_item item;

    for (int trial = 0; trial < 3; trial++) begin
      item = matrix_item::type_id::create($sformatf("item_%0d", trial));
      if (!item.randomize())
        $fatal(1, "Input randomization failed for trial %0d", trial);

      calculate_expected(item, C_expected);

      $display("Trial %0d: %s", trial, item.get_name());
      $display("A = [%0d, %0d]", item.A[0][0], item.A[0][1]);
      $display("    [%0d, %0d]", item.A[1][0], item.A[1][1]);
      $display("B = [%0d, %0d]", item.B[0][0], item.B[0][1]);
      $display("    [%0d, %0d]", item.B[1][0], item.B[1][1]);
      $display("C_expected = [%0d, %0d]", C_expected[0][0], C_expected[0][1]);
      $display("             [%0d, %0d]", C_expected[1][0], C_expected[1][1]);
    end

    $finish;
  end
endmodule
