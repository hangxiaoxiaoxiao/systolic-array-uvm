// Lesson 48: pass a parameterized UVM input object to the matching reference helper.
// Compile this file alone with UVM enabled; top: parameterized_reference_object_demo.
// This UVM integration has NOT been compiled or simulated. Known results below
// are static expectations; lesson 46's runs do not validate this class integration.
// Three directed fixtures check 17 mathematical results and range flags if run.
// There is no DUT output, UVM phase execution, interface, clock, or scoreboard here.
// Input object handles are read only during calculation; output arrays receive values.
// A later call overwrites the supplied output arrays. This is not a prediction queue.
// Positive DIN_WIDTH, N, and M are required. No output overflow policy is selected.
`include "uvm_macros.svh"

package parameterized_reference_lesson_pkg;
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
  // A parameterized namespace for the pure reference calculation and its types.
  // No object instance or UVM factory registration is needed for this helper.
  class matrix_reference #(
    int DIN_WIDTH = 8,
    int N = 2,
    int M = 3
  );
    localparam int PRODUCT_WIDTH = 2 * DIN_WIDTH;
    localparam int EXTRA_BITS = (M > 1) ? $clog2(M) : 0;
    localparam int ACC_WIDTH = PRODUCT_WIDTH + EXTRA_BITS;
    localparam logic signed [PRODUCT_WIDTH-1:0] OUTPUT_MIN_NARROW =
      {1'b1, {(PRODUCT_WIDTH-1){1'b0}}};
    localparam logic signed [PRODUCT_WIDTH-1:0] OUTPUT_MAX_NARROW =
      {1'b0, {(PRODUCT_WIDTH-1){1'b1}}};
    localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MIN = OUTPUT_MIN_NARROW;
    localparam logic signed [ACC_WIDTH-1:0] OUTPUT_MAX = OUTPUT_MAX_NARROW;

    // Derive input and output types from this helper's same parameter set.
    typedef matrix_item #(DIN_WIDTH, N, M) item_t;
    typedef logic signed [ACC_WIDTH-1:0] sum_array_t[0:N-1][0:N-1];
    typedef logic fits_array_t[0:N-1][0:N-1];

    // static: call through the class type, without creating a reference instance.
    // This method uses only parameters, local constants/types, arguments and locals.
    static function void calculate(
      input item_t item,
      output sum_array_t C_full,
      output fits_array_t fits_output
    );
      logic signed [DIN_WIDTH-1:0] input_value;
      logic signed [PRODUCT_WIDTH-1:0] product;
      logic signed [ACC_WIDTH-1:0] extended_product, sum;

      if (DIN_WIDTH < 1 || N < 1 || M < 1) begin
        $fatal(1, "PARAMETER_ERROR: DIN_WIDTH, N, and M must be positive");
        return;
      end
      if (item == null) begin
        $fatal(1, "NULL_INPUT: reference requires an input item");
        return;
      end
      // Copy to a scalar before $isunknown, retaining lesson 46's guard pattern.
      foreach (item.A[i,k]) begin
        input_value = item.A[i][k];
        if ($isunknown(input_value)) begin
          $fatal(1, "UNKNOWN_INPUT: A[%0d][%0d] contains X/Z", i, k);
          return;
        end
      end
      foreach (item.B[k,j]) begin
        input_value = item.B[k][j];
        if ($isunknown(input_value)) begin
          $fatal(1, "UNKNOWN_INPUT: B[%0d][%0d] contains X/Z", k, j);
          return;
        end
      end

      for (int i = 0; i < N; i++) begin
        for (int j = 0; j < N; j++) begin
          sum = '0;
          for (int k = 0; k < M; k++) begin
            product = item.A[i][k] * item.B[k][j];
            extended_product = {{EXTRA_BITS{product[PRODUCT_WIDTH-1]}}, product};
            sum = sum + extended_product;
          end
          C_full[i][j] = sum;
          fits_output[i][j] = (sum >= OUTPUT_MIN) && (sum <= OUTPUT_MAX);
        end
      end
    endfunction
  endclass
endpackage

module parameterized_reference_object_demo;
  import uvm_pkg::*;
  import parameterized_reference_lesson_pkg::*;

  typedef matrix_reference #(8, 2, 3) ref23_t;
  typedef matrix_reference #(4, 3, 2) ref32_t;
  // Get the input types from the helpers to avoid repeating mismatched parameters.
  typedef ref23_t::item_t item23_t;
  typedef ref32_t::item_t item32_t;

  initial begin
    item23_t item23;
    item32_t item32;
    ref23_t::sum_array_t C23;
    ref23_t::fits_array_t fits23;
    ref32_t::sum_array_t C32;
    ref32_t::fits_array_t fits32;
    int checked_elements;

    checked_elements = 0;
    item23 = item23_t::type_id::create("item23");
    item32 = item32_t::type_id::create("item32");
    if (item23 == null || item32 == null)
      $fatal(1, "CREATE_FAILED: expected two transaction objects");

    // Case 1: each result is (-1*2) + (-1*2) + (-1*2) = -6.
    foreach (item23.A[i,k]) item23.A[i][k] = -1;
    foreach (item23.B[k,j]) item23.B[k][j] =  2;
    item23.describe();
    ref23_t::calculate(item23, C23, fits23);
    foreach (C23[i,j]) begin
      if (C23[i][j] !== -18'sd6 || fits23[i][j] !== 1'b1)
        $fatal(1, "REFERENCE_MISMATCH: case1 C[%0d][%0d]=%0d fits=%b, expected -6/1",
               i, j, C23[i][j], fits23[i][j]);
      checked_elements++;
    end
    $display("REFERENCE_CASE_MATCHED: case1, 4 results of -6 fit signed 16 bits");

    // Case 2: each result is (1*-2) + (1*-2) = -4.
    foreach (item32.A[i,k]) item32.A[i][k] =  1;
    foreach (item32.B[k,j]) item32.B[k][j] = -2;
    item32.describe();
    ref32_t::calculate(item32, C32, fits32);
    foreach (C32[i,j]) begin
      if (C32[i][j] !== -9'sd4 || fits32[i][j] !== 1'b1)
        $fatal(1, "REFERENCE_MISMATCH: case2 C[%0d][%0d]=%0d fits=%b, expected -4/1",
               i, j, C32[i][j], fits32[i][j]);
      checked_elements++;
    end
    $display("REFERENCE_CASE_MATCHED: case2, 9 results of -4 fit signed 8 bits");

    // Case 3: reuse item23 only after the first synchronous calculation/check.
    // No queue or monitor retains it. The next call replaces C23/fits23 values.
    // Three products of (-128*-128) give 49152, outside signed 16-bit output.
    foreach (item23.A[i,k]) item23.A[i][k] = 8'sh80;
    foreach (item23.B[k,j]) item23.B[k][j] = 8'sh80;
    ref23_t::calculate(item23, C23, fits23);
    foreach (C23[i,j]) begin
      if (C23[i][j] !== 18'sd49152 || fits23[i][j] !== 1'b0)
        $fatal(1, "REFERENCE_MISMATCH: case3 C[%0d][%0d]=%0d fits=%b, expected 49152/0",
               i, j, C23[i][j], fits23[i][j]);
      checked_elements++;
    end
    $display("REFERENCE_CASE_MATCHED: case3, 4 exact results of 49152 exceed signed 16 bits");

    if (checked_elements != 17)
      $fatal(1, "CHECK_COUNT: expected 17 reference elements, got %0d", checked_elements);
    $display("REFERENCE_OBJECT_DEMO_PASS: 17 reference sums and range flags matched; no DUT checked.");
    $finish;
  end
endmodule
