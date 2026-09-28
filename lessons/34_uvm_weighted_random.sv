// Lesson 34: use dist to favor endpoints while allowing all signed 8-bit values.
// Compile this file alone with UVM enabled; top: weighted_random_demo.
// Not yet compiled or simulated with UVM.
// This is a focused data-generation exercise based on lesson 33.
// It does not extend lesson 32's timed fixture or its hard-coded scoreboard.
// No run_test(), driver, monitor, coverage collector, or DUT is instantiated.
// Successful randomization is not a matrix arithmetic or coverage pass.
`include "uvm_macros.svh"

package weighted_random_lesson_pkg;
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

module weighted_random_demo;
  import uvm_pkg::*;
  import weighted_random_lesson_pkg::*;

  initial begin
    matrix_item item;

    // Four fresh objects; values and matrices may repeat or miss categories.
    // These few samples cannot establish the statistical distribution.
    // No coverage results or frequency measurements are collected here.
    for (int trial = 0; trial < 4; trial++) begin
      item = matrix_item::type_id::create($sformatf("weighted_item_%0d", trial));

      // A/B remain rand. Disable the old small-range scenario so endpoints
      // and all other signed 8-bit values are eligible for this call.
      // If left enabled, it would restrict the solution to [-4:4]; dist does
      // not override it or guarantee endpoint hits against that restriction.
      item.small_values.constraint_mode(0);

      // Per element, without other restrictions on A/B:
      // -128 has weight 25; the WHOLE interior range has weight 50;
      // +127 has weight 25. The intended category probabilities are 25/50/25%.
      // These are relative weights, not required counts in four trials.
      // := gives each value its weight; :/ shares a total across a range.
      // The three disjoint entries include all 256 signed 8-bit values.
      if (!item.randomize() with {
        foreach (A[i,k]) A[i][k] dist {
          -128       := 25,
          [-127:126] :/ 50,
          127        := 25
        };
        foreach (B[k,j]) B[k][j] dist {
          -128       := 25,
          [-127:126] :/ 50,
          127        := 25
        };
      }) begin
        $fatal(1, "Weighted randomization failed for trial %0d", trial);
      end

      // Print only after successful generation. No expected C is computed.
      $display("Trial %0d: %s", trial, item.get_name());
      $display("A = [%0d, %0d]", item.A[0][0], item.A[0][1]);
      $display("    [%0d, %0d]", item.A[1][0], item.A[1][1]);
      $display("B = [%0d, %0d]", item.B[0][0], item.B[0][1]);
      $display("    [%0d, %0d]", item.B[1][0], item.B[1][1]);

      // small_values remains disabled on this object. The inline dist applies
      // only to this randomize() call. A later unqualified randomize() would
      // need its own scenario constraints if this object were reused.
      // Here the next iteration creates a fresh object instead.
    end

    $finish;
  end
endmodule
