// Lesson 18: use the mathematical reference in a UVM matrix scoreboard.
// Compile this lesson by itself with UVM enabled; top: matrix_scoreboard_demo.
// Not yet compiled or simulated with UVM, including +INJECT_ERROR.
// This is a standalone scoreboard exercise with manually supplied C_actual.
// There is no DUT, interface, driver, monitor, or cycle-level verification here.
// Pairing A/B with a monitored C is a separate integration step, not implemented.
`timescale 1ns/1ps
`include "uvm_macros.svh"

package matrix_scoreboard_lesson_pkg;
  import uvm_pkg::*;

  localparam int DIN_WIDTH = 8;
  localparam int N = 2;
  localparam int M = 2;

  // One already-associated calculation to check. The arrays contain values,
  // not interface handles. This fixed fixture is not randomized.
  class matrix_check_item extends uvm_sequence_item;
    `uvm_object_utils(matrix_check_item)

    logic signed [DIN_WIDTH-1:0] A[0:N-1][0:M-1];
    logic signed [DIN_WIDTH-1:0] B[0:M-1][0:N-1];
    logic signed [2*DIN_WIDTH-1:0] C_actual[0:N-1][0:N-1];

    // Factory registration does not automate copying or comparing these fields.
    function new(string name = "matrix_check_item");
      super.new(name);
    endfunction
  endclass

  // Adapted from lesson 9. Only A and B determine the prediction.
  // C_actual is deliberately never read by this function.
  function automatic void calculate_expected(
    input matrix_check_item item,
    output logic signed [2*DIN_WIDTH-1:0] C_expected[0:N-1][0:N-1]
  );
    int signed product;
    int signed sum;

    if (item == null)
      $fatal(1, "Reference calculation requires an input item");

    // Reject unknown input bits before numeric calculation/conversion.
    foreach (item.A[i,k]) begin
      if ($isunknown(item.A[i][k]))
        $fatal(1, "Unknown input bits in A[%0d][%0d]", i, k);
    end
    foreach (item.B[k,j]) begin
      if ($isunknown(item.B[k][j]))
        $fatal(1, "Unknown input bits in B[%0d][%0d]", k, j);
    end

    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        sum = 0;
        for (int k = 0; k < M; k++) begin
          product = item.A[i][k] * item.B[k][j];
          sum += product;
        end
        // Sufficient arithmetic width for this fixed 8-bit, M=2 lesson.
        // Overflow policy is unspecified in the PDF; do not assume wrap/saturate.
        if (sum < -32768 || sum > 32767)
          $fatal(1, "Reference sum exceeds the lesson's 16-bit result range");
        C_expected[i][j] = sum;
      end
    end
  endfunction

  class matrix_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(matrix_scoreboard)

    uvm_analysis_imp #(matrix_check_item, matrix_scoreboard) analysis_in;
    int unsigned received_count = 0;
    int unsigned mismatch_count = 0;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_in = new("analysis_in", this);
    endfunction

    function void write(matrix_check_item item);
      logic signed [2*DIN_WIDTH-1:0] C_expected[0:N-1][0:N-1];

      if (item == null) begin
        `uvm_fatal("NULL_ITEM", "Scoreboard got a null matrix item")
        return;
      end
      received_count++;
      calculate_expected(item, C_expected);

      for (int i = 0; i < N; i++) begin
        for (int j = 0; j < N; j++) begin
          // Four-state comparison catches unknown bits in the received result.
          if (item.C_actual[i][j] !== C_expected[i][j]) begin
            mismatch_count++;
            `uvm_error("MATRIX_MISMATCH",
              $sformatf("C[%0d][%0d]: expected=%0d actual=%0d",
                        i, j, C_expected[i][j], item.C_actual[i][j]))
          end
        end
      end
      // Do not change the received object or generate actual data from expected.
    endfunction
  endclass

  // This test supplies a fixture directly to exercise the scoreboard in isolation.
  class matrix_scoreboard_test extends uvm_test;
    `uvm_component_utils(matrix_scoreboard_test)

    uvm_analysis_port #(matrix_check_item) result_ap;
    matrix_scoreboard scoreboard;

    function new(string name = "matrix_scoreboard_test",
                 uvm_component parent = null);
      super.new(name, parent);
      result_ap = new("result_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      scoreboard = matrix_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      result_ap.connect(scoreboard.analysis_in);
    endfunction

    task run_phase(uvm_phase phase);
      matrix_check_item item;
      phase.raise_objection(this);
      item = matrix_check_item::type_id::create("known_matrix_case");

      item.A[0][0] =  1; item.A[0][1] = -2;
      item.A[1][0] =  3; item.A[1][1] =  4;
      item.B[0][0] = -1; item.B[0][1] =  2;
      item.B[1][0] =  5; item.B[1][1] = -3;

      // Manually supplied stand-in results from the known lesson 3 fixture.
      // These are not DUT observations and are not copied from C_expected.
      item.C_actual[0][0] = -11; item.C_actual[0][1] =  8;
      item.C_actual[1][0] =  17; item.C_actual[1][1] = -6;

      if ($test$plusargs("INJECT_ERROR")) begin
        item.C_actual[1][0] = 18;
        `uvm_info("INJECT_ERROR", "Deliberately changed C_actual[1][0] to 18", UVM_LOW)
      end

      // Calls write() synchronously; all comparisons finish before this returns.
      result_ap.write(item);
      if (scoreboard.received_count != 1)
        `uvm_fatal("MATRIX_COUNT", "Scoreboard did not receive exactly one item")
      if (scoreboard.mismatch_count != 0)
        `uvm_fatal("MATRIX_CHECK_FAILED",
          $sformatf("Found %0d mismatched matrix elements",
                    scoreboard.mismatch_count))
      `uvm_info("MATRIX_FIXTURE",
        "Manually supplied matrix matched the reference; no DUT was verified.",
        UVM_LOW)
      phase.drop_objection(this);
    endtask
  endclass
endpackage

module matrix_scoreboard_demo;
  import uvm_pkg::*;
  import matrix_scoreboard_lesson_pkg::*;
  initial run_test("matrix_scoreboard_test");
endmodule
