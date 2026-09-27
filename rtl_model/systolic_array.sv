// ----------------------------------------------------------------------------
// systolic_array.sv -- cycle-accurate model of the N x N weight-stationary
// systolic array used as the DUT stand-in for the TetraMem DV assignment.
//
// Protocol (docs/dv-architecture-and-assumptions.md, A1..A7).  All times are
// clock cycles counted from the first cycle after reset release; a signal
// "presented on cycle t" is driven during cycle t and sampled at its end.
//
//   * Slots are N cycles long.  slot_cnt is the cycle index inside the slot.
//   * During slot s, b_din[j] presents the B rows of the chunk that slot s+1
//     will compute, one row per cycle in REVERSE row order, lane j delayed by
//     j cycles.  The rows travel down the forwarded-weight path of column j.
//     On slot cycle N-1 (+j) the last row has arrived and every PE of the
//     column captures its own row into the shadow weight register.  The same
//     pulse propagates down the column one PE per cycle and swaps
//     shadow -> active in PE(k,j) on slot cycle N-1+k+j, exactly one cycle
//     before row 0 of the next slot reaches that PE.
//   * During slot s+1, a_din[k] presents A[r][cN+k] on slot cycle r, lane k
//     delayed by k.  Row r flows through PE row k; the partial sums flow down
//     the columns and C[r][j] (or the running partial sum) leaves c_dout[j]
//     on cycle t_r + N + j, where t_r is the cycle lane 0 presented row r.
//   * c_din[j] is the partial-sum input of PE(0,j): 0 for the first chunk of
//     a multiplication, the same-cycle loop-back of c_dout[j] for later chunks
//     (external control, see tb/top/loopback_shim.sv).
//   * in_valid is a pulse on the slot cycle where lane 0 presents the last
//     row of the last chunk; out_valid is the same pulse 2N-1 cycles later,
//     on the cycle where C[N-1][N-1] is on c_dout[N-1].
// ----------------------------------------------------------------------------

module pe #(parameter int DIN_WIDTH = 8) (
  input  logic                          clk,
  input  logic                          rst_n,
  input  logic signed [DIN_WIDTH-1:0]   a_in,       // activation from the left
  input  logic signed [DIN_WIDTH-1:0]   b_in,       // weight stream from above
  input  logic signed [2*DIN_WIDTH-1:0] c_in,       // partial sum from above
  input  logic                          w_load,     // capture b_in into shadow (column broadcast)
  input  logic                          w_swap,     // shadow -> active (propagated down the column)
  output logic signed [DIN_WIDTH-1:0]   a_out,      // forwarded to the right
  output logic signed [DIN_WIDTH-1:0]   b_out,      // forwarded to below
  output logic signed [2*DIN_WIDTH-1:0] c_out,      // partial sum to below
  output logic                          w_swap_out  // swap pulse to the PE below
);
  logic signed [DIN_WIDTH-1:0]   w_shadow;   // next weight (double buffer)
  logic signed [DIN_WIDTH-1:0]   w_active;   // weight used for computing
  logic signed [2*DIN_WIDTH-1:0] prod;

  assign prod = a_in * w_active;              // signed product, 2*DIN_WIDTH bits

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_out      <= '0;
      b_out      <= '0;
      c_out      <= '0;
      w_shadow   <= '0;
      w_active   <= '0;
      w_swap_out <= 1'b0;
    end else begin
      a_out      <= a_in;
      b_out      <= b_in;
      w_swap_out <= w_swap;
      c_out      <= prod + c_in;              // wraps to 2*DIN_WIDTH bits (A8)
      if (w_load) w_shadow <= b_in;
      // In the top PE of a column load and swap coincide: take b_in directly.
      if (w_swap) w_active <= (w_load ? b_in : w_shadow);
    end
  end
endmodule


module systolic_array #(
  parameter int DIN_WIDTH = 8,
  parameter int N         = 4
) (
  input  logic                          rst_n,
  input  logic                          clk,
  input  logic signed [2*DIN_WIDTH-1:0] c_din  [0:N-1],
  input  logic signed [DIN_WIDTH-1:0]   a_din  [0:N-1],
  input  logic signed [DIN_WIDTH-1:0]   b_din  [0:N-1],
  input  logic                          in_valid,
  output logic signed [2*DIN_WIDTH-1:0] c_dout [N-1:0],
  output logic                          out_valid
);
  // ---------------------------------------------------------------- slot counter
  localparam int CW = (N > 1) ? $clog2(N) : 1;
  logic [CW-1:0] slot_cnt;      // slot cycle index; 0 on the first cycle after reset
  logic          slot_last;     // slot_cnt == N-1

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)               slot_cnt <= CW'(N-1);   // wraps to 0 at the first edge
    else if (slot_cnt == N-1) slot_cnt <= '0;
    else                      slot_cnt <= slot_cnt + 1'b1;
  end
  assign slot_last = (slot_cnt == CW'(N-1));

  // ---------------------------------- column control pulse: slot_last delayed by j
  logic col_ctrl [0:N-1];
  assign col_ctrl[0] = slot_last;
  generate
    for (genvar gj = 1; gj < N; gj++) begin : g_ctrl
      always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) col_ctrl[gj] <= 1'b0; else col_ctrl[gj] <= col_ctrl[gj-1];
    end
  endgenerate

  // ----------------------------------------------------------------- PE mesh
  logic signed [DIN_WIDTH-1:0]   a_w [0:N-1][0:N];   // a_w[k][j] = a into PE(k,j)
  logic signed [DIN_WIDTH-1:0]   b_w [0:N][0:N-1];   // b_w[k][j] = b into PE(k,j)
  logic signed [2*DIN_WIDTH-1:0] c_w [0:N][0:N-1];   // c_w[k][j] = c into PE(k,j)
  logic                          s_w [0:N][0:N-1];   // swap pulse into PE(k,j)

  generate
    for (genvar gk = 0; gk < N; gk++) begin : g_row
      assign a_w[gk][0] = a_din[gk];
    end
    for (genvar gj = 0; gj < N; gj++) begin : g_col
      assign b_w[0][gj] = b_din[gj];
      assign c_w[0][gj] = c_din[gj];
      assign s_w[0][gj] = col_ctrl[gj];
      assign c_dout[gj] = c_w[N][gj];
    end
    for (genvar gk = 0; gk < N; gk++) begin : g_mesh_row
      for (genvar gj = 0; gj < N; gj++) begin : g_mesh_col
        pe #(.DIN_WIDTH(DIN_WIDTH)) u_pe (
          .clk        (clk),
          .rst_n      (rst_n),
          .a_in       (a_w[gk][gj]),
          .b_in       (b_w[gk][gj]),
          .c_in       (c_w[gk][gj]),
          .w_load     (col_ctrl[gj]),
          .w_swap     (s_w[gk][gj]),
          .a_out      (a_w[gk][gj+1]),
          .b_out      (b_w[gk+1][gj]),
          .c_out      (c_w[gk+1][gj]),
          .w_swap_out (s_w[gk+1][gj])
        );
      end
    end
  endgenerate

  // ------------------------------------------------- in_valid -> out_valid
  // Last row presented on lane 0 at in_valid; C[N-1][N-1] is on c_dout[N-1]
  // (N-1) + N + (N-1) - (N-1) = 2N-1 cycles later.
  localparam int OUT_LAT = 2*N - 1;
  logic [OUT_LAT-1:0] v_pipe;
  generate
    if (OUT_LAT == 1) begin : g_lat1
      always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) v_pipe <= '0; else v_pipe <= in_valid;
    end else begin : g_latn
      always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) v_pipe <= '0; else v_pipe <= {v_pipe[OUT_LAT-2:0], in_valid};
    end
  endgenerate
  assign out_valid = v_pipe[OUT_LAT-1];

endmodule
