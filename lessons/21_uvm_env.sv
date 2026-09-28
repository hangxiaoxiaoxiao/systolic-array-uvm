// Lesson 21: let a UVM environment create and connect the teaching components.
// Compile this lesson by itself with UVM enabled; top: env_demo.
// Not yet compiled or simulated with UVM, including +INJECT_ERROR.
// The test starts a manual fixture source; the env builds and connects components.
// The source sends objects, not signal samples: it is not a monitor.
// No DUT, interface, driver, monitor, clocks, reset handling, or latency checks.
// Earlier virtual-interface/config_db driver paths do not apply to this lesson.
// All sends are synchronous at time zero. Inputs are registered before outputs,
// and complete output matrices return in input order. No PDF timing is modeled.
// Actual matrices are manually supplied; out-of-order completion is unsupported.
`timescale 1ns/1ps
`include "uvm_macros.svh"

package env_lesson_pkg;
  import uvm_pkg::*;

  // Declare these suffix types once in this package, before their use.
  // The generated imps forward write() to write_input() or write_output().
  `uvm_analysis_imp_decl(_input)
  `uvm_analysis_imp_decl(_output)

  localparam int DIN_WIDTH = 8;
  localparam int N = 2;
  localparam int M = 2;

  class matrix_input_item extends uvm_sequence_item;
    `uvm_object_utils(matrix_input_item)
    logic signed [DIN_WIDTH-1:0] A[0:N-1][0:M-1];
    logic signed [DIN_WIDTH-1:0] B[0:M-1][0:N-1];

    function new(string name = "matrix_input_item");
      super.new(name);
    endfunction
  endclass

  class matrix_output_item extends uvm_sequence_item;
    `uvm_object_utils(matrix_output_item)
    logic signed [2*DIN_WIDTH-1:0] C_actual[0:N-1][0:N-1];

    function new(string name = "matrix_output_item");
      super.new(name);
    endfunction
  endclass

  class matrix_expected_item extends uvm_object;
    `uvm_object_utils(matrix_expected_item)
    logic signed [2*DIN_WIDTH-1:0] C_expected[0:N-1][0:N-1];
    int unsigned case_id; // Local log number, not a DUT tag used for matching.

    function new(string name = "matrix_expected_item");
      super.new(name);
    endfunction
  endclass

  // Adapted from lesson 9. Only A and B determine the prediction.
  // The input item has no actual-result fields.
  function automatic void calculate_expected(
    input matrix_input_item item,
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

  class matrix_dual_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(matrix_dual_scoreboard)

    uvm_analysis_imp_input #(matrix_input_item, matrix_dual_scoreboard) input_in;
    uvm_analysis_imp_output #(matrix_output_item, matrix_dual_scoreboard) output_in;
    matrix_expected_item expected_queue[$];
    int unsigned enqueued_count = 0;
    int unsigned received_count = 0;
    int unsigned error_count = 0;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      input_in = new("input_in", this);
      output_in = new("output_in", this);
    endfunction

    // Called through input_in when the source writes a complete A/B item.
    // This function has no delays; it computes and queues the prediction.
    function void write_input(matrix_input_item input_item);
      matrix_expected_item expected;
      // Each queue entry must reference its own object. Compute before enqueue.
      expected = matrix_expected_item::type_id::create("expected");
      calculate_expected(input_item, expected.C_expected);
      expected.case_id = enqueued_count + 1;
      expected_queue.push_back(expected);
      enqueued_count++;
      // The queue stores this handle; do not modify the enqueued object.
      // Later changes to input_item do not change these calculated array values.
    endfunction

    // Called through output_in for a complete C item. FIFO ordering still applies.
    function void write_output(matrix_output_item actual);
      matrix_expected_item expected;
      if (actual == null) begin
        error_count++;
        `uvm_fatal("NULL_OUTPUT", "Scoreboard got a null output item")
        return;
      end
      received_count++;
      if (expected_queue.size() == 0) begin
        error_count++;
        `uvm_error("UNEXPECTED_OUTPUT", "No expected matrix is queued for this output")
        return;
      end

      // FIFO matching: take the oldest unmatched prediction, not a matching ID.
      expected = expected_queue.pop_front();
      for (int i = 0; i < N; i++) begin
        for (int j = 0; j < N; j++) begin
          if (actual.C_actual[i][j] !== expected.C_expected[i][j]) begin
            error_count++;
            `uvm_error("MATRIX_MISMATCH",
              $sformatf("Case %0d C[%0d][%0d]: expected=%0d actual=%0d",
                        expected.case_id, i, j, expected.C_expected[i][j],
                        actual.C_actual[i][j]))
          end
        end
      end
    endfunction
  endclass

  // Artificial data source for this lesson: no signal sampling or DUT access.
  // It owns only its analysis ports; it does not know the scoreboard instance.
  class matrix_fixture_source extends uvm_component;
    `uvm_component_utils(matrix_fixture_source)

    uvm_analysis_port #(matrix_input_item) input_ap;
    uvm_analysis_port #(matrix_output_item) result_ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      input_ap = new("input_ap", this);
      result_ap = new("result_ap", this);
    endfunction

    // Explicitly called by the test. No automatic run_phase sender or objections.
    task send_cases();
      matrix_input_item input1, input2;
      matrix_output_item output1, output2;
      input1 = matrix_input_item::type_id::create("input1");
      input2 = matrix_input_item::type_id::create("input2");
      output1 = matrix_output_item::type_id::create("output1");
      output2 = matrix_output_item::type_id::create("output2");

      input1.A[0][0] =  1; input1.A[0][1] = -2;
      input1.A[1][0] =  3; input1.A[1][1] =  4;
      input1.B[0][0] = -1; input1.B[0][1] =  2;
      input1.B[1][0] =  5; input1.B[1][1] = -3;
      // Independent manually supplied answers, not copies of reference output.
      output1.C_actual[0][0] = -11; output1.C_actual[0][1] =  8;
      output1.C_actual[1][0] =  17; output1.C_actual[1][1] = -6;

      input2.A[0][0] = -2; input2.A[0][1] = 1;
      input2.A[1][0] =  0; input2.A[1][1] = 3;
      input2.B[0][0] =  1; input2.B[0][1] = 0;
      input2.B[1][0] =  0; input2.B[1][1] = 1;
      // Multiplication by the identity matrix preserves this second A matrix.
      output2.C_actual[0][0] = -2; output2.C_actual[0][1] = 1;
      output2.C_actual[1][0] =  0; output2.C_actual[1][1] = 3;

      // Both inputs precede both outputs. These calls do not advance time.
      // No real monitor is connected; parallel callback ordering is not modeled.
      input_ap.write(input1);
      input_ap.write(input2);

      if ($test$plusargs("INJECT_ERROR")) begin
        output1.C_actual[1][0] = 18;
        `uvm_info("INJECT_ERROR", "Deliberately changed first C[1][0] to 18", UVM_LOW)
      end
      result_ap.write(output1);
      result_ap.write(output2);
    endtask
  endclass

  // The environment owns construction and connections, not test start/stop.
  class matrix_env extends uvm_env;
    `uvm_component_utils(matrix_env)

    matrix_fixture_source source;
    matrix_dual_scoreboard scoreboard;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      source = matrix_fixture_source::type_id::create("source", this);
      scoreboard = matrix_dual_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      source.input_ap.connect(scoreboard.input_in);
      source.result_ap.connect(scoreboard.output_in);
    endfunction
  endclass

  class matrix_env_test extends uvm_test;
    `uvm_component_utils(matrix_env_test)

    matrix_env env;

    function new(string name = "matrix_env_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = matrix_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      // Connections are ready before run_phase. The test chooses when to send.
      env.source.send_cases();

      if (env.scoreboard.enqueued_count != 2 || env.scoreboard.received_count != 2)
        `uvm_fatal("MATRIX_COUNT", "Expected two input registrations and two outputs")
      if (env.scoreboard.expected_queue.size() != 0)
        `uvm_fatal("PENDING_RESULTS", "Some expected matrices have no matching output")
      if (env.scoreboard.error_count != 0)
        `uvm_fatal("QUEUE_CHECK_FAILED",
          $sformatf("Found %0d checking errors", env.scoreboard.error_count))
      `uvm_info("ENV_FIXTURE",
        "Env connections checked with two manual fixtures; no DUT was verified.",
        UVM_LOW)
      phase.drop_objection(this);
    endtask
  endclass
endpackage

module env_demo;
  import uvm_pkg::*;
  import env_lesson_pkg::*;
  initial run_test("matrix_env_test");
endmodule
