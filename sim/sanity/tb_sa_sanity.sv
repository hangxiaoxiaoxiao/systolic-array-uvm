// ----------------------------------------------------------------------------
// tb_sa_sanity.sv -- plain SystemVerilog (no UVM) sanity test for the
// systolic_array model.  It drives the slot protocol of
// docs/dv-architecture-and-assumptions.md (A1..A7) for a list of back-to-back
// matrix multiplications, reconstructs C from c_dout and compares against a
// wrap-around reference.  Run with:
//
//   $ verilator --binary --timing --trace -Wno-fatal -GN=2 -GDIN_WIDTH=8 \
//     rtl_model/systolic_array.sv sim/sanity/tb_sa_sanity.sv \
//     --top-module tb_sa_sanity --Mdir sim/sanity/obj -o Vsanity && ./sim/sanity/obj/Vsanity
//
// The same cycle arithmetic is what the UVM driver and monitor implement.
// ----------------------------------------------------------------------------
module tb_sa_sanity #(
  parameter int N         = 2,
  parameter int DIN_WIDTH = 8,
  parameter int NUM_MM    = 6,      // number of consecutive multiplications
  parameter int M_MAX     = 9,      // random M in [1, M_MAX]
  parameter int SEED      = 1
);
  localparam int W  = DIN_WIDTH;
  localparam int CW = 2*DIN_WIDTH;

  logic clk = 0;
  logic rst_n = 0;
  always #5 clk = ~clk;

  logic signed [CW-1:0] c_din  [0:N-1];
  logic signed [W-1:0]  a_din  [0:N-1];
  logic signed [W-1:0]  b_din  [0:N-1];
  logic                 in_valid;
  logic signed [CW-1:0] c_dout [N-1:0];
  logic                 out_valid;

  // loop-back shim (A5): c_din[j] = loop_en[j] ? c_dout[j] : 0
  logic loop_en [0:N-1];
  for (genvar j = 0; j < N; j++) begin : g_loop
    assign c_din[j] = loop_en[j] ? c_dout[j] : '0;
  end

  systolic_array #(.DIN_WIDTH(W), .N(N)) dut (
    .rst_n(rst_n), .clk(clk), .c_din(c_din), .a_din(a_din), .b_din(b_din),
    .in_valid(in_valid), .c_dout(c_dout), .out_valid(out_valid));

  // ------------------------------------------------------------ stimulus data
  typedef struct {
    int M;
    int A [0:255][0:255];   // A[r][k], r < N, k < M
    int B [0:255][0:255];   // B[k][j], k < M, j < N
    int C [0:255][0:255];   // reference, wrapped to CW bits
  } mm_t;
  mm_t mm [NUM_MM];

  function automatic int wrap(longint v);
    longint m = 64'd1 << CW;
    longint r = v % m; if (r < 0) r += m;
    if (r >= (m >> 1)) r -= m;
    return int'(r);
  endfunction

  function automatic void make_ref(ref mm_t x);
    for (int r = 0; r < N; r++)
      for (int j = 0; j < N; j++) begin
        longint acc = 0;
        for (int k = 0; k < x.M; k++) acc += longint'(x.A[r][k]) * longint'(x.B[k][j]);
        x.C[r][j] = wrap(acc);
      end
  endfunction

  function automatic int to_signed(int v);  // wrap any int into the DIN_WIDTH signed range
    int m = 1 << W;
    int r = v % m; if (r < 0) r += m;
    if (r >= (m >> 1)) r -= m;
    return r;
  endfunction

  function automatic int rnd_signed();   // full DIN_WIDTH signed range
    return to_signed($urandom_range(0, (1 << W) - 1));
  endfunction

  // ------------------------------------------------------- per-cycle schedule
  // lane-0 timing: slot s = cycles [s*N, s*N+N).  Slot 0 preloads chunk (0,0).
  int total_slots, total_cycles;
  int a_drv   [0:4095][0:15];   // a_din[k] to present on cycle t (already skewed)
  int b_drv   [0:4095][0:15];   // b_din[j] on cycle t (already skewed)
  bit loop_drv[0:4095][0:15];   // loop_en[j] on cycle t
  bit iv_drv  [0:4095];         // in_valid on cycle t
  int c_time  [NUM_MM][0:15][0:15]; // cycle on which C[q][r][j] is on c_dout[j]
  int c_got   [NUM_MM][0:15][0:15];
  int ov_time [NUM_MM];         // expected out_valid cycle per multiplication
  int cyc = -1;                 // current cycle index (cycle 0 = first after reset)

  function automatic int ceil_div(int a, int b); return (a + b - 1) / b; endfunction

  task automatic build_schedule();
    int s = 1;   // first compute slot; slot 0 is preload-only
    for (int t = 0; t < 4096; t++) begin
      iv_drv[t] = 0;
      for (int k = 0; k < 16; k++) begin a_drv[t][k] = 0; b_drv[t][k] = 0; loop_drv[t][k] = 0; end
    end
    for (int q = 0; q < NUM_MM; q++) begin
      int K = ceil_div(mm[q].M, N);
      for (int c = 0; c < K; c++) begin
        int t0 = s * N;             // lane-0 start of the compute slot of chunk (q,c)
        // A rows of chunk c: a_din[k] = A[r][cN+k] on cycle t0 + r, lane k delayed by k
        for (int r = 0; r < N; r++)
          for (int k = 0; k < N; k++)
            a_drv[t0 + r + k][k] = (c*N + k < mm[q].M) ? mm[q].A[r][c*N + k] : 0;
        // B rows of chunk c, preloaded during the PREVIOUS slot, reverse order,
        // lane j delayed by j:  b_din[j] = B[cN+N-1-i][j] on cycle (t0-N) + i + j
        for (int i = 0; i < N; i++)
          for (int j = 0; j < N; j++) begin
            int row = c*N + N - 1 - i;
            b_drv[t0 - N + i + j][j] = (row < mm[q].M) ? mm[q].B[row][j] : 0;
          end
        // loop-back enable for chunks c > 0: row r reaches PE(0,j) on t0 + r + j
        if (c > 0)
          for (int r = 0; r < N; r++)
            for (int j = 0; j < N; j++) loop_drv[t0 + r + j][j] = 1;
        // last chunk: in_valid on the last row of lane 0; results C[r][j] on t0+r+N+j
        if (c == K - 1) begin
          iv_drv[t0 + N - 1] = 1;
          ov_time[q] = t0 + N - 1 + 2*N - 1;
          for (int r = 0; r < N; r++)
            for (int j = 0; j < N; j++) c_time[q][r][j] = t0 + r + N + j;
        end
        s++;
      end
    end
    total_slots  = s;
    total_cycles = total_slots * N + 3 * N;
  endtask

  // ------------------------------------------------------------------ driver
  // Values for cycle t are applied right after posedge t (NBA) and are
  // sampled by the DUT at posedge t+1.
  task automatic drive_cycle(int t);
    for (int k = 0; k < N; k++) begin
      a_din[k]   <= W'(a_drv[t][k]);
      b_din[k]   <= W'(b_drv[t][k]);
      loop_en[k] <= loop_drv[t][k];
    end
    in_valid <= iv_drv[t];
  endtask

  // ----------------------------------------------------------------- monitor
  int errors = 0;
  bit ov_seen [NUM_MM];
  task automatic sample_cycle(int t);
    for (int q = 0; q < NUM_MM; q++) begin
      for (int r = 0; r < N; r++)
        for (int j = 0; j < N; j++)
          if (c_time[q][r][j] == t) c_got[q][r][j] = int'(c_dout[j]);
      if (ov_time[q] == t) begin
        ov_seen[q] = 1;
        if (!out_valid) begin errors++; $display("ERROR cyc %0d: out_valid expected for mm %0d", t, q); end
      end else if (out_valid && t < total_cycles) begin
        bit expected = 0;
        for (int q2 = 0; q2 < NUM_MM; q2++) if (ov_time[q2] == t) expected = 1;
        if (!expected) begin errors++; $display("ERROR cyc %0d: unexpected out_valid", t); end
      end
    end
  endtask

  // -------------------------------------------------------------------- main
  initial begin
    $dumpfile("sanity.vcd");
    $dumpvars(0, tb_sa_sanity);
    void'($urandom(SEED));
    // multiplication 0: the assignment's 2x2 example shape, small values
    for (int q = 0; q < NUM_MM; q++) begin
      mm[q].M = (q == 0) ? N : (q == 1) ? 2*N : $urandom_range(1, M_MAX);
      for (int r = 0; r < N; r++)
        for (int k = 0; k < mm[q].M; k++)
          mm[q].A[r][k] = (q == 0) ? to_signed(r*N + k + 1) : rnd_signed();
      for (int k = 0; k < mm[q].M; k++)
        for (int j = 0; j < N; j++)
          mm[q].B[k][j] = (q == 0) ? to_signed(N*N + k*N + j + 1) : rnd_signed();
      make_ref(mm[q]);
    end
    build_schedule();
    $display("N=%0d DIN_WIDTH=%0d  %0d multiplications, %0d slots, %0d cycles",
             N, W, NUM_MM, total_slots, total_cycles);

    for (int k = 0; k < N; k++) begin a_din[k] = 0; b_din[k] = 0; loop_en[k] = 0; end
    in_valid = 0;
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst_n = 1;                       // released mid-cycle: the next posedge starts cycle 0
    for (int t = 0; t < total_cycles; t++) begin
      @(posedge clk);
      cyc = t;
      drive_cycle(t);
      @(negedge clk);
      sample_cycle(t);
      if (N == 2 && t < 4*N + 3)     // print the first multiplication's cycle table
        $display("cyc %2d slot %0d.%0d | a_din %4d %4d | b_din %4d %4d | iv %0d | c_dout %5d %5d | ov %0d",
                 t, t / N, t % N, a_din[0], a_din[1], b_din[0], b_din[1], in_valid,
                 c_dout[0], c_dout[1], out_valid);
    end

    for (int q = 0; q < NUM_MM; q++) begin
      bit ok;                        // (a declaration with an initializer here would be static)
      ok = ov_seen[q];
      for (int r = 0; r < N; r++)
        for (int j = 0; j < N; j++)
          if (c_got[q][r][j] !== mm[q].C[r][j]) begin
            ok = 0; errors++;
            $display("MISMATCH mm %0d C[%0d][%0d]: got %0d exp %0d", q, r, j, c_got[q][r][j], mm[q].C[r][j]);
          end
      $display("mm %0d: M=%0d chunks=%0d out_valid@%0d %s", q, mm[q].M, ceil_div(mm[q].M, N),
               ov_time[q], ok ? "PASS" : "FAIL");
    end
    if (errors == 0) $display("SANITY PASS"); else $display("SANITY FAIL (%0d errors)", errors);
    $finish;
  end
endmodule
