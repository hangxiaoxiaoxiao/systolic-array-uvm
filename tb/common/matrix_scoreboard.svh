`ifndef MATRIX_SCOREBOARD_SVH
`define MATRIX_SCOREBOARD_SVH

// Each stream must preserve matrix order. The two monitor callbacks may arrive
// in either order, including output first at the same simulation time. This is
// not an ID-based reorder buffer and supplies no DUT completion/timeout policy.
class matrix_scoreboard #(
  int W = 8,
  int N = 2,
  int M = 3
) extends uvm_scoreboard;
  `uvm_component_param_utils(matrix_scoreboard #(W, N, M))

  typedef matrix_scoreboard #(W, N, M) this_t;
  typedef matrix_item #(W, N, M) item_t;
  typedef matrix_result #(W, N) result_t;
  typedef matrix_reference #(W, N, M) reference_t;
  typedef matrix_prediction #(W, N, M) prediction_t;

  uvm_analysis_imp_matrix_input #(item_t, this_t) input_in;
  uvm_analysis_imp_matrix_output #(result_t, this_t) output_in;

  // Owned snapshots; exposed for diagnostics, not for mutation by publishers.
  prediction_t predictions[$];
  result_t actual_results[$];
  longint unsigned input_count = 0;
  longint unsigned output_count = 0;
  longint unsigned compared_count = 0;
  longint unsigned compared_elements = 0;
  longint unsigned mismatch_count = 0;
  bit comparison_blocked = 1'b0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    input_in = new("input_in", this);
    output_in = new("output_in", this);
    if (W < 1 || N < 1 || M < 1) begin
      comparison_blocked = 1'b1;
      `uvm_fatal("MATRIX_PARAMETERS", "W, N, and M must be positive")
      return;
    end
  endfunction

  // Macro-generated imps use unique callback names within the common package.
  function void write_matrix_input(item_t item);
    write_input(item);
  endfunction

  function void write_matrix_output(result_t actual);
    write_output(actual);
  endfunction

  function void write_input(item_t item);
    prediction_t prediction;
    bit matched;
    // Counts record observed callbacks, including invalid callbacks. Such faults
    // latch comparison_blocked and cannot disappear from the final accounting.
    input_count++;
    prediction = prediction_t::type_id::create($sformatf("prediction_%0d", input_count - 1));
    if (prediction == null) begin
      predictions.push_back(null);
      comparison_blocked = 1'b1;
      `uvm_fatal("MATRIX_PREDICTION_CREATE", "Factory did not create a prediction")
      return;
    end
    prediction.case_id = input_count - 1;
    // All arithmetic completes synchronously; no publisher-owned handle remains.
    prediction.reference_valid = reference_t::calculate(item, prediction.C_full, prediction.fits_output);
    predictions.push_back(prediction);
    if (!prediction.reference_valid) begin
      comparison_blocked = 1'b1;
      `uvm_error("REFERENCE_FAILED", $sformatf("case=%0d could not be calculated; invalid prediction retained", prediction.case_id))
      return;
    end
    matched = try_match();
  endfunction

  function void write_output(result_t actual);
    result_t snapshot;
    bit matched;
    output_count++;
    if (actual == null) begin
      actual_results.push_back(null);
      comparison_blocked = 1'b1;
      `uvm_fatal("MATRIX_OUTPUT_NULL", "Output callback supplied a null result")
      return;
    end
    snapshot = result_t::type_id::create($sformatf("actual_%0d", output_count - 1));
    if (snapshot == null) begin
      actual_results.push_back(null);
      comparison_blocked = 1'b1;
      `uvm_fatal("MATRIX_RESULT_CREATE", "Factory did not create a result snapshot")
      return;
    end
    snapshot.copy(actual);
    actual_results.push_back(snapshot);
    matched = try_match();
  endfunction

  // False means comparison cannot proceed; it never means a numeric mismatch.
  // On failure leave both heads intact, so later writes cannot mispair frames.
  protected function bit try_match();
    prediction_t expected;
    result_t actual;
    longint unsigned new_mismatches, new_elements;
    if (comparison_blocked)
      return 1'b0;
    while (predictions.size() != 0 && actual_results.size() != 0) begin
      if (!compare_pair(predictions[0], actual_results[0], new_mismatches, new_elements)) begin
        comparison_blocked = 1'b1;
        return 1'b0;
      end
      expected = predictions.pop_front();
      actual = actual_results.pop_front();
      compared_count++;
      compared_elements += new_elements;
      mismatch_count += new_mismatches;
      `uvm_info("MATRIX_COMPARED",
        $sformatf("case=%0d elements=%0d mismatches=%0d", expected.case_id, new_elements, new_mismatches), UVM_HIGH)
    end
    return 1'b1;
  endfunction

  protected function bit compare_pair(
    prediction_t expected,
    result_t actual,
    output longint unsigned new_mismatches,
    output longint unsigned new_elements
  );
    logic signed [2*W-1:0] actual_element;
    logic signed [reference_t::ACC_WIDTH-1:0] actual_full;
    logic signed [reference_t::ACC_WIDTH-1:0] expected_element;
    new_mismatches = 0;
    new_elements = 0;
    if (expected == null || actual == null) begin
      `uvm_fatal("MATRIX_COMPARISON_NULL", "Comparison requires both a prediction and an output snapshot")
      return 1'b0;
    end
    if (!expected.reference_valid) begin
      `uvm_error("MATRIX_REFERENCE_INVALID", $sformatf("case=%0d has no valid reference result", expected.case_id))
      return 1'b0;
    end
    // Validate the whole frame before counting any comparisons or removing it.
    foreach (expected.C_full[i,j]) begin
      expected_element = expected.C_full[i][j];
      if ($isunknown(expected_element) || expected.fits_output[i][j] !== 1'b1) begin
        `uvm_error("REFERENCE_NOT_COMPARABLE",
          $sformatf("case=%0d C[%0d][%0d]=%0d is unknown or outside signed %0d-bit output; overflow behavior is unspecified",
                    expected.case_id, i, j, expected_element, 2*W))
        return 1'b0;
      end
    end
    foreach (actual.C[i,j]) begin
      actual_element = actual.C[i][j];
      actual_full = {{reference_t::EXTRA_BITS{actual_element[2*W-1]}}, actual_element};
      new_elements++;
      // Case inequality counts X/Z in an observed result as a mismatch.
      if (actual_full !== expected.C_full[i][j]) begin
        new_mismatches++;
        `uvm_error("MATRIX_MISMATCH",
          $sformatf("W=%0d N=%0d M=%0d case=%0d C[%0d][%0d] expected=%0d actual=%0d (0x%0h)",
                    W, N, M, expected.case_id, i, j, expected.C_full[i][j], actual_element, actual_element))
      end
    end
    return 1'b1;
  endfunction

  // Queue/accounting completion only. A drained scoreboard can still contain
  // numeric mismatches; tests must also inspect mismatch_count and UVM reports.
  function bit is_drained();
    return !comparison_blocked && predictions.size() == 0 && actual_results.size() == 0 &&
           input_count == output_count && compared_count == input_count &&
           compared_elements == compared_count * N * N;
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (input_count == 0)
      `uvm_error("MATRIX_NO_INPUTS", "No input matrices were observed")
    if (output_count == 0)
      `uvm_error("MATRIX_NO_OUTPUTS", "No output matrices were observed")
    if (input_count != output_count || compared_count != input_count)
      `uvm_error("MATRIX_COUNT",
        $sformatf("inputs=%0d outputs=%0d compared=%0d", input_count, output_count, compared_count))
    if (predictions.size() != 0)
      `uvm_error("PENDING_RESULTS", $sformatf("Pending predictions=%0d", predictions.size()))
    if (actual_results.size() != 0)
      `uvm_error("PENDING_ACTUALS", $sformatf("Pending outputs=%0d", actual_results.size()))
    if (compared_elements != compared_count * N * N)
      `uvm_error("MATRIX_ELEMENT_COUNT",
        $sformatf("Compared elements=%0d expected=%0d", compared_elements, compared_count * N * N))
    if (comparison_blocked)
      `uvm_error("MATRIX_COMPARISON_BLOCKED", "An invalid or non-comparable transaction prevented completion; queued state was retained")
    if (mismatch_count != 0)
      `uvm_error("RESULT_CHECK_FAILED", $sformatf("Found %0d element mismatches", mismatch_count))
  endfunction
endclass

`endif
