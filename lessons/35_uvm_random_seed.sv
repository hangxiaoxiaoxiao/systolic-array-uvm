// Lesson 35: record and explicitly set the RNG seed of each random item.
// Compile this file alone with UVM enabled; top: random_seed_demo.
// Not yet compiled or simulated with UVM.
// This is a focused data-generation exercise based on lesson 34.
// It does not extend lesson 32's timed fixture or its hard-coded scoreboard.
// No run_test(), driver, monitor, coverage collector, or DUT is instantiated.
// Successful randomization is not a matrix arithmetic or coverage pass.
// Default base seed is 2026; optional simulation argument: +ITEM_SEED=1234.
// Trial 0..3 uses base_seed+trial (32-bit unsigned addition).
// This seeds each item only, not the whole simulator or any other object.
// Replay requires the same simulator/version, code, constraints, relevant state,
// and random call order. No identical results across simulators are promised.
// Different seeds can still produce identical matrices; no uniqueness guarantee.
`include "uvm_macros.svh"

package random_seed_lesson_pkg;
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

module random_seed_demo;
  import uvm_pkg::*;
  import random_seed_lesson_pkg::*;

  initial begin
    matrix_item item;
    int unsigned base_seed;
    int unsigned trial_seed;

    if (!$value$plusargs("ITEM_SEED=%d", base_seed))
      base_seed = 32'd2026;
    $display("BASE_SEED: %0d; per-item seeds are base_seed + trial", base_seed);

    // Four fresh objects; values and matrices may repeat or miss categories.
    // These few samples cannot establish the statistical distribution.
    // No coverage results or frequency measurements are collected here.
    for (int trial = 0; trial < 4; trial++) begin
      item = matrix_item::type_id::create($sformatf("seeded_item_%0d", trial));

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
      // Seed AFTER factory construction, before this object's randomize().
      // No other process receives or randomizes this object in this exercise.
      // Each fresh item gets a seed; repeatedly resetting one reused object to
      // the same seed would restart its RNG, not advance its random sequence.
      trial_seed = base_seed + trial;
      $display("ITEM_SEED: trial=%0d, seed=%0d", trial, trial_seed);
      item.srandom(trial_seed);
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
        $fatal(1, "Randomization failed for trial %0d, item seed %0d",
               trial, trial_seed);
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
