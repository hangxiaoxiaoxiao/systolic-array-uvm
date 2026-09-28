// Lesson 39: compare independent manual results with queued full-width predictions.
// Compile this file alone with UVM enabled; top: result_matching_demo.
// Default and +INJECT_ERROR paths have NOT been compiled or simulated with UVM.
// Uses two directed fixtures, not lesson 38's random generation or seed options.
// Both inputs are registered before the two complete results are submitted.
// This fixture submits results in input order; no DUT ordering contract is implied.
// No DUT, interface, monitor, UVM phases, or cycle/latency checking is implemented.
// Reference arithmetic follows lesson 36; this object/queue integration is unrun.
// Only representable results are compared; an unresolved overflow stops the fixture
// before its prediction is consumed, without selecting a DUT overflow policy.
// Hand-filled result checks are not evidence that a DUT has been verified.
`timescale 1ns/1ps
`include "uvm_macros.svh"

package result_matching_lesson_pkg;
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

    int unsigned case_id;
    logic signed [ACC_WIDTH-1:0] C_full[0:N-1][0:N-1];
    logic fits_output[0:N-1][0:N-1];

    // Local metadata helps identify records; it is not a tag returned by a DUT.
    // This object does not store an A/B snapshot or an input item handle.
    function new(string name = "matrix_prediction");
      super.new(name);
    endfunction
  endclass

  // Complete 16-bit result carrier. In this lesson C is filled manually,
  // independently of the reference calculation; it is not sampled from a DUT.
  class matrix_result extends uvm_object;
    `uvm_object_utils(matrix_result)
    logic signed [PRODUCT_WIDTH-1:0] C[0:N-1][0:N-1];

    function new(string name = "matrix_result");
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

module result_matching_demo;
  import uvm_pkg::*;
  import result_matching_lesson_pkg::*;

  matrix_prediction predictions[$];
  int unsigned enqueued_count = 0;
  int unsigned received_count = 0;
  int unsigned compared_elements = 0;
  int unsigned mismatch_count = 0;

  function automatic void enqueue_prediction(input matrix_item item,
                                             input int unsigned case_id);
    matrix_prediction prediction;
    prediction = matrix_prediction::type_id::create(
                   $sformatf("prediction_%0d", case_id));
    prediction.case_id = case_id;
    calculate_reference(item, prediction.C_full, prediction.fits_output);
    predictions.push_back(prediction);
    enqueued_count++;
    // Each enqueued object is complete and is only read from this point onward.
  endfunction

  function automatic void compare_result(input matrix_result actual);
    matrix_prediction expected;
    logic signed [PRODUCT_WIDTH-1:0] actual_element;
    logic signed [ACC_WIDTH-1:0] actual_full;

    if (actual == null) begin
      $fatal(1, "NULL_RESULT: no result object was supplied");
      return;
    end
    if (predictions.size() == 0) begin
      $fatal(1, "UNEXPECTED_RESULT: no prediction is waiting");
      return;
    end
    expected = predictions[0]; // Inspect the oldest record without removing it.
    if (expected == null) begin
      $fatal(1, "NULL_PREDICTION: queue contains a null handle");
      return;
    end
    foreach (expected.fits_output[i,j]) begin
      if (expected.fits_output[i][j] !== 1'b1) begin
        $fatal(1, "REFERENCE_NOT_COMPARABLE: case=%0d C[%0d][%0d]=%0d needs a defined output overflow rule; no DUT verdict",
               expected.case_id, i, j, expected.C_full[i][j]);
        return;
      end
    end

    // All prerequisites passed. Match by FIFO order, not by a returned ID.
    expected = predictions.pop_front();
    received_count++;
    foreach (actual.C[i,j]) begin
      actual_element = actual.C[i][j];
      // Sign extend the 16-bit actual value into a signed 17-bit variable.
      // Do not narrow C_full to 16 bits before comparing.
      actual_full = {actual_element[PRODUCT_WIDTH-1], actual_element};
      compared_elements++;
      // Known reference versus case inequality also detects actual X/Z bits.
      if (actual_full !== expected.C_full[i][j]) begin
        mismatch_count++;
        $display("RESULT_MISMATCH: case=%0d C[%0d][%0d] expected=%0d manual_actual=%0d",
                 expected.case_id, i, j, expected.C_full[i][j], actual_element);
      end
    end
    $display("RESULT_COMPARED: case=%0d, remaining_predictions=%0d",
             expected.case_id, predictions.size());
  endfunction

  initial begin
    matrix_item input0, input1;
    matrix_result result0, result1;

    input0 = matrix_item::type_id::create("input0");
    input1 = matrix_item::type_id::create("input1");
    result0 = matrix_result::type_id::create("result0");
    result1 = matrix_result::type_id::create("result1");

    // Fully assigned directed inputs. No randomize() is called in this lesson.
    input0.A[0][0] =  1; input0.A[0][1] = -2;
    input0.A[1][0] =  3; input0.A[1][1] =  4;
    input0.B[0][0] = -1; input0.B[0][1] =  2;
    input0.B[1][0] =  5; input0.B[1][1] = -3;

    input1.A[0][0] = -2; input1.A[0][1] = 1;
    input1.A[1][0] =  0; input1.A[1][1] = 3;
    input1.B[0][0] =  1; input1.B[0][1] = 0;
    input1.B[1][0] =  0; input1.B[1][1] = 1;

    enqueue_prediction(input0, 0);
    enqueue_prediction(input1, 1);
    if (enqueued_count != 2 || predictions.size() != 2)
      $fatal(1, "ENQUEUE_COUNT: expected two saved predictions before results");

    // Independent hand-calculated output fixtures, not copies of C_full.
    result0.C[0][0] = -11; result0.C[0][1] =  8;
    result0.C[1][0] =  17; result0.C[1][1] = -6;
    // The second B is the identity, so the hand-calculated result equals A.
    result1.C[0][0] = -2; result1.C[0][1] = 1;
    result1.C[1][0] =  0; result1.C[1][1] = 3;

    if ($test$plusargs("INJECT_ERROR")) begin
      result0.C[1][0] = 18;
      $display("INJECT_ERROR: first manual C[1][0] changed from 17 to 18");
    end

    // Synchronous time-zero submissions in input order; no response timing model.
    compare_result(result0);
    compare_result(result1);

    if (received_count != 2 || compared_elements != 8)
      $fatal(1, "RESULT_COUNT: received=%0d compared_elements=%0d; expected 2 and 8",
             received_count, compared_elements);
    if (predictions.size() != 0)
      $fatal(1, "PENDING_RESULTS: %0d predictions remain", predictions.size());
    if (mismatch_count != 0)
      $fatal(1, "TEACHING_CHECK_FAILED: %0d mismatches in manual results", mismatch_count);

    $display("TEACHING_CHECK_PASS: two manual matrices matched queued predictions; no DUT verified.");
    $finish;
  end
endmodule
