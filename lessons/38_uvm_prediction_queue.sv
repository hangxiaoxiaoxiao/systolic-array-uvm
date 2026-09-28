// Lesson 38: retain every full-width prediction in a fresh object and queue.
// Compile this file alone with UVM enabled; top: prediction_queue_demo.
// Not yet compiled or simulated with UVM.
// This extends lesson 37 with stored predictions and generation metadata.
// It does not extend lesson 32's timed fixture or its hard-coded scoreboard.
// No run_test(), driver, monitor, coverage collector, or DUT is instantiated.
// Only predictions are produced and retained: no observed C or DUT comparison.
// Queue entries are object handles, not automatic deep copies.
// Each prediction is created separately, fully filled, then left read-only.
// Queue order is generation order; no DUT output-order contract is assumed here.
// Lesson 36's directed arithmetic checks ran; this UVM integration has not.
// Overflow is flagged without selecting a DUT truncation/saturation policy.
// Default base seed is 2026; optional simulation argument: +ITEM_SEED=1234.
// Trial 0..3 uses base_seed+trial (32-bit unsigned addition).
// This seeds each item only, not the whole simulator or any other object.
// Replay requires the same simulator/version, code, constraints, relevant state,
// and random call order. No identical results across simulators are promised.
// Different seeds can still produce identical matrices; no uniqueness guarantee.
`include "uvm_macros.svh"

package prediction_queue_lesson_pkg;
  import uvm_pkg::*;

  localparam int DIN_WIDTH = 8;
  localparam int N = 2;
  localparam int M = 2;
  localparam int PRODUCT_WIDTH = 2 * DIN_WIDTH;
  localparam int ACC_WIDTH = PRODUCT_WIDTH + 1; // Fixed M=2, not arbitrary M.
  localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MIN = -17'sd32768;
  localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MAX =  17'sd32767;

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

  // A reference result record. These fields are calculated/assigned, not random.
  class matrix_prediction extends uvm_object;
    `uvm_object_utils(matrix_prediction)

    int unsigned trial_id;
    int unsigned item_seed;
    logic signed [ACC_WIDTH-1:0] C_full[0:N-1][0:N-1];
    logic fits_output[0:N-1][0:N-1];

    // Local metadata helps identify records; it is not a tag returned by a DUT.
    // This object does not store an A/B snapshot or an input item handle.
    function new(string name = "matrix_prediction");
      super.new(name);
    endfunction
  endclass

  // input passes the object HANDLE. This function reads A/B without modifying them.
  // Output arrays contain mathematical predictions, not DUT observations.
  function automatic void calculate_reference(
    input matrix_item item,
    output logic signed [ACC_WIDTH-1:0] C_full[0:N-1][0:N-1],
    output logic fits_output[0:N-1][0:N-1]
  );
    logic signed [DIN_WIDTH-1:0] input_value;
    logic signed [PRODUCT_WIDTH-1:0] product;
    logic signed [ACC_WIDTH-1:0] extended_product;
    logic signed [ACC_WIDTH-1:0] sum;

    if (item == null) begin
      $fatal(1, "NULL_INPUT: reference requires an input item");
      return;
    end

    // Reject unknown inputs before any arithmetic; retain lesson 36's scalar
    // copy for the unknown-value check. No A/B fields are written here.
    foreach (item.A[i,k]) begin
      input_value = item.A[i][k];
      if ($isunknown(input_value))
        $fatal(1, "UNKNOWN_INPUT: A[%0d][%0d] contains X/Z", i, k);
    end
    foreach (item.B[k,j]) begin
      input_value = item.B[k][j];
      if ($isunknown(input_value))
        $fatal(1, "UNKNOWN_INPUT: B[%0d][%0d] contains X/Z", k, j);
    end

    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        sum = '0;
        for (int k = 0; k < M; k++) begin
          // Signed operands and a signed 16-bit destination preserve the product.
          product = item.A[i][k] * item.B[k][j];
          // Assign the sign-extended bits to a SIGNED 17-bit variable first.
          // Both operands of the following addition are then signed 17-bit.
          extended_product = {product[PRODUCT_WIDTH-1], product};
          sum = sum + extended_product;
        end
        C_full[i][j] = sum;
        fits_output[i][j] = (sum >= OUTPUT_MIN) && (sum <= OUTPUT_MAX);
      end
    end
  endfunction
endpackage

module prediction_queue_demo;
  import uvm_pkg::*;
  import prediction_queue_lesson_pkg::*;

  initial begin
    matrix_item item;
    matrix_prediction prediction;
    matrix_prediction predictions[$];
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

      // Print the actual generated inputs; the reference below uses this item.
      $display("Trial %0d: %s", trial, item.get_name());
      $display("A = [%0d, %0d]", item.A[0][0], item.A[0][1]);
      $display("    [%0d, %0d]", item.A[1][0], item.A[1][1]);
      $display("B = [%0d, %0d]", item.B[0][0], item.B[0][1]);
      $display("    [%0d, %0d]", item.B[1][0], item.B[1][1]);

      // Allocate a NEW result object for this input; never reuse an enqueued one.
      prediction = matrix_prediction::type_id::create(
                     $sformatf("prediction_%0d", trial));
      prediction.trial_id = trial;
      prediction.item_seed = trial_seed;
      // Calculate from the SAME A/B just printed. Every output field is filled
      // before publishing the handle. The input object is only read.
      calculate_reference(item, prediction.C_full, prediction.fits_output);
      predictions.push_back(prediction);
      // push_back stores this handle. Do not change this object's fields later.
      // Next iteration creates a new object instead of overwriting this one.
      $display("PREDICTION_QUEUED: trial=%0d, seed=%0d, queue_size=%0d",
               prediction.trial_id, prediction.item_seed, predictions.size());

      // small_values remains disabled on this object. The inline dist applies
      // only to this randomize() call. A later unqualified randomize() would
      // need its own scenario constraints if this object were reused.
      // Here the next iteration creates a fresh object instead.
    end

    // Inspect the retained results AFTER all four inputs have been generated.
    // Indexing reads a handle; it does not remove the entry or make a copy.
    // There are no actual outputs to match, so do not pop or claim a check pass.
    $display("STORED_PREDICTIONS: count=%0d", predictions.size());
    foreach (predictions[q]) begin
      prediction = predictions[q];
      foreach (prediction.C_full[i,j]) begin
        $display("REFERENCE_ONLY: queue_index=%0d, trial=%0d, seed=%0d, C_full[%0d][%0d]=%0d, fits_signed_16=%b",
                 q, prediction.trial_id, prediction.item_seed,
                 i, j, prediction.C_full[i][j], prediction.fits_output[i][j]);
      end
    end

    $finish;
  end
endmodule
