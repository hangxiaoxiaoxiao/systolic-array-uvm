# DV Architecture and Proposed Assumptions

Status: **proposal v0.1 — open for discussion.** This document is the
companion to [`spec-questions.md`](spec-questions.md) and
[`verification-plan.md`](verification-plan.md): where those two list what the
assignment leaves open, this one proposes a concrete default for each item
(`A<n>` below), the testbench architecture that keeps every default isolated
behind one config field or helper function, and the checkers, tests and
coverage that follow from them. Nothing here is implemented yet.

| `spec-questions.md` item | proposed default below |
|---|---|
| frame boundary, `in_valid`/`out_valid` semantics, per-lane element mapping | A1, A2, A3 |
| `c_din` loop-back, `M != N` scheduling | A5 (with A1/A2) |
| arithmetic width, overflow policy | A6 |
| `din`/`dout` bit layout | A7 |
| FIFO handshake, read latency, write-when-full | A8 |
| `M_minus_one` latching | A9 |
| output-FIFO back-pressure | A10 |
| clock relationship, reset semantics | A11, A12 |
| latency / throughput checks | A13 |

---

## 1. Scope

Verify `C = A x B` for signed integer matrices on two DUT levels:

* **Module level** — `systolic_array #(DIN_WIDTH=8, N=4)`: NxN PE mesh,
  one clock, pin-level interface.
* **Sub-system level** — `sub_sys #(DIN_WIDTH=8, N=4, BUS_WIDTH=2*DIN_WIDTH*N)`:
  input FIFO + controller + data alignment + `systolic_array` + output FIFO,
  bus side on `sys_clk`, array side on `sr_clk`.

Matrix shapes: `A` is `N x M`, `B` is `M x N`, `C` is `N x N`, with
`M = M_minus_one + 1` in `[1, 256]`. Each element of `A`/`B` is `DIN_WIDTH`-bit
signed; each element of `C` is `2*DIN_WIDTH`-bit signed.

Out of scope: the `D` addend (`C = AxB + D`) — explicitly dropped by the assignment.

---

## 2. Interface contract and assumptions

### 2.1 Data ordering (both levels)

* **A1 — one sample per cycle = one column of A + one row of B.**
  On sample `k` (`k = 0..M-1`): `a_din[i] = A[i][k]` for `i = 0..N-1`,
  `b_din[j] = B[k][j]` for `j = 0..N-1`. This is the outer-product formulation
  `C = sum_k A[:,k] (x) B[k,:]` and is the only reading consistent with the
  interface widths (`N` elements of A per sample although A has `M` columns)
  and with the sub-system statement "each sample includes one column of A and
  one row of B".
* **A2 — the M samples of one matrix multiplication are presented on M
  consecutive clock cycles**, `in_valid = 1` only on the last one (`k = M-1`).
  There is no per-sample valid, so a matrix starts on the cycle after the
  previous `in_valid` (or after reset). Idle cycles between multiplications are
  allowed; during idle the driver drives `a_din = b_din = 0`, which contributes
  nothing to an accumulating array.
* **A3 — output order.** `c_dout` delivers `C` one **row** per cycle on `N`
  consecutive cycles, row `0` first, `out_valid = 1` on the last row
  (`c_dout[j] = C[i][j]` on the cycle for row `i`). This is the de-skewed
  ("data aligned") view. Config knob `io_skewed` switches driver and monitor
  to the diagonal wavefront shown in the assignment figures (column `j` delayed
  by `j` cycles) in case the raw module exposes skewed I/O.
* **A4 — `c_dout` is zero whenever no result row is being presented.**
  Checked against the cycle model's output window.

### 2.2 Partial-sum input

* **A5 — `c_din` is driven to 0 at module level.** The assignment says the
  signal "needs to be reset to 0 when a new matrix starts" and that loop-back
  is a top-level/controller concern. With A1/A2 the module accumulates the
  `M` partial products internally, so loop-back is not needed for `M > N`.
  A `c_din_loopback` knob in the driver emulates the controller
  (`c_din <= c_dout` of the previous cycle, forced to 0 on the first sample of
  a matrix) for exploratory tests only; it is off by default.

### 2.3 Arithmetic

* **A6 — signed two's-complement, accumulator wraps.** The exact sum needs
  `2*DIN_WIDTH + ceil(log2(M))` bits but the output is `2*DIN_WIDTH` bits;
  e.g. `DIN_WIDTH = 8`, `M = 2`: `(-128)*(-128)*2 = 32768 > 32767`.
  The reference model computes the exact sum in a wide integer and truncates
  to `2*DIN_WIDTH` bits (modular wrap). A `no_overflow` constraint mode limits
  `|A|, |B| <= floor(sqrt((2^(2*DIN_WIDTH-1) - 1) / M))` for clean directed
  tests; the default random mode uses the full range so the wrap path is
  exercised and covered.

### 2.4 Sub-system bus

* **A7 — `din` packing.** `din[N*DIN_WIDTH-1:0]` = the A column,
  element `i` at `[i*DIN_WIDTH +: DIN_WIDTH]`; `din[2*N*DIN_WIDTH-1:N*DIN_WIDTH]`
  = the B row, element `j` at `[N*DIN_WIDTH + j*DIN_WIDTH +: DIN_WIDTH]`.
  `dout` carries one C row, element `j` at `[j*2*DIN_WIDTH +: 2*DIN_WIDTH]`.
  One `pack_sample()/unpack_sample()/pack_row()/unpack_row()` set in
  `tb/common` is the only place that knows this layout.
* **A8 — FIFO handshake.** `wr_fifo` is a write strobe sampled on `sys_clk`;
  the TB never asserts it while `in_fifo_full = 1` (a negative test verifies
  such a write is ignored). `rd_fifo` is a pop strobe; `dout` is valid on the
  cycle **after** `rd_fifo` is sampled with `out_fifo_empty = 0`
  (standard, non-FWFT FIFO). Knob `fifo_fwft` switches the monitor to
  first-word-fall-through.
* **A9 — `M_minus_one` is quasi-static.** It may only change while the
  sub-system is idle (all launched multiplications drained). Tests change it
  between batches, never mid-stream.
* **A10 — no output data loss under back-pressure.** The array cannot stall,
  so the controller launches a multiplication only when the output FIFO has
  room for `N` rows. The TB checks with slow readers that every row arrives
  exactly once, in order.
* **A11 — clocks are asynchronous** (arbitrary ratio and phase). FIFO depth
  is a model parameter (`FIFO_DEPTH`, default 16 samples).

### 2.5 Reset and timing

* **A12 — `rst_n` is asynchronous-assert, synchronous-deassert** in every
  domain. A reset in the middle of traffic discards in-flight data; the
  scoreboard flushes its expectation queue on reset.
* **A13 — latency is defined by the cycle model**, not hard-coded in the TB.
  Monitors align on `in_valid` / `out_valid` only (sliding window of the last
  `N` — or `2N-1` when skewed — rows). Expected latency
  `L(N, M)` and the `M`-cycle throughput are derived from the model and
  checked by SVA properties that can be disabled for a DUT with different timing.

---

## 3. DV architecture and reuse

```
                      +-----------------------------------------------+
                      |  matmul_item  (A[N][M], B[M][N], M, C_exp)    |  shared transaction
                      +-----------------------------------------------+
                                 |                          |
                    module level |               sub-system |
                                 v                          v
                 sa_agent (active)                bus_agent (active, 2 clocks)
                 driver / monitor / sequencer     wr driver+monitor (sys_clk)
                 pin level                        rd driver+monitor (sys_clk)
                                 |                          |
                                 |          sa_agent (PASSIVE, bound to the internal
                                 |          systolic_array instance via `bind`)
                                 v                          v
                 +------------------------------------------------------------+
                 |  scoreboard (in-order expectation queue) + reference model |  shared
                 |  functional coverage                                       |  shared
                 +------------------------------------------------------------+
```

* One transaction type at both levels: the driver of each agent knows how to
  serialize it (pins vs. packed bus samples); the monitors rebuild it.
* `sa_env` (module level) is instantiated inside `subsys_env`; at the
  sub-system level its agent is passive and bound to the internal array, so
  the same scoreboard checks the array output and the FIFO output of the same
  multiplication — end-to-end and white-box in one run.
* Parameterization without parameterized UVM classes: interfaces are sized
  by `MAX_N` / `MAX_DIN_WIDTH` from `tb/common/sa_params_pkg.sv`; the actual
  `N`, `DIN_WIDTH`, `BUS_WIDTH` live in the env config object and are read
  from the compile-time parameters via `$value$plusargs` / package constants.
* Clock periods and phase for `sys_clk` / `sr_clk` come from plusargs
  (`+SYS_CLK_PS=`, `+SR_CLK_PS=`, `+SR_CLK_PHASE_PS=`), so one compile covers
  every clock relationship; `N` and `DIN_WIDTH` are swept by a regression
  script over compile configurations.

---

## 4. Checkers

| Check | Where | Notes |
|---|---|---|
| `C == ref(A, B)` per multiplication, in order | scoreboard | reference model in `tb/common`, wrap per A6 |
| every launched multiplication produces exactly one result | scoreboard | end-of-test: expectation queue empty |
| `c_dout == 0` outside result windows (A4) | SVA / monitor | window from cycle model |
| `out_valid` pulses once per `in_valid`, never without one | SVA | |
| latency `L(N, M)` and `M`-cycle throughput (A13) | SVA | disable-able |
| no write while full is honoured, no data loss under slow reader (A8, A10) | bus monitor + scoreboard | |
| reset flushes state (A12) | scoreboard + directed test | |
| internal array result == FIFO result (sub-system) | passive `sa_agent` | white-box cross-check |
| TB self-check: injected model bugs are caught | `sim/` regression | e.g. drop the last partial product when `M > N` |

---

## 5. Stimulus

Base sequence: `matmul_seq` generates `num_matmul` back-to-back items with
random `M`, random signed data, random idle gaps (module level) or random
`wr_fifo` / `rd_fifo` pacing (sub-system level).

| Test | Level | Purpose |
|---|---|---|
| `smoke` | both | one multiplication, `M = N`, small values |
| `rand_consecutive` | both | 50+ back-to-back multiplications, random `M` in `[1, 16]`, no gaps |
| `rand_gaps` | both | random idle cycles / bus pacing between multiplications |
| `m_extremes` | both | `M = 1`, `M = N`, `M = 256` |
| `data_extremes` | both | all `+max`, all `-min`, alternating signs, zeros |
| `overflow_wrap` | both | forces accumulator wrap (A6) |
| `reset_midstream` | both | reset during input / compute / output phases |
| `clk_ratio_sweep` | sub-system | `sys:sr` = 1:1, 2:1, 1:2, 3:2, 1:3, random phase |
| `backpressure` | sub-system | fast writer vs. slow reader and vice-versa; hits `in_fifo_full` and `out_fifo_empty` |
| `m_change_between_batches` | sub-system | A9 |
| `write_when_full` | sub-system | negative test for A8 |
| `param_sweep` | both | `N in {2, 4, 8}`, `DIN_WIDTH in {4, 8, 16}` via regression script |

---

## 6. Functional coverage

* `M` bins: `1`, `2..N-1`, `N`, `N+1..255`, `256`
* data: per-element extremes (`min`, `-1`, `0`, `1`, `max`) on A and B
* accumulator overflow occurred / not occurred per multiplication
* idle gap between multiplications: `0`, `1`, `>1`
* sub-system: `in_fifo_full` hit, `out_fifo_empty` seen while a multiplication is in flight, clock ratio bin, `M_minus_one` change count
* reset phase: idle / input / compute / output
* cross: `M` x overflow, `M` x gap

---

## 7. Deliverables and tooling

* Source under `tb/`, `rtl_model/`, run scripts under `sim/`.
* `docs/`: this plan (final version), DV structure, list of frozen assumptions.
* `results/`: logs and waveform screenshots of consecutive multiplications at
  both levels. Primary simulator: EDA Playground (UVM 1.2); the file set is
  kept EDA-Playground-friendly (few files, includes via `` `include ``).

---

## 8. Open questions to settle before implementation

1. A3: does the raw `systolic_array` expose aligned or diagonal-skewed I/O? (default: aligned)
2. A5: should module-level tests exercise `c_din` loop-back at all? (default: no)
3. A6: wrap vs. saturate on accumulator overflow? (default: wrap)
4. A8: standard vs. FWFT output FIFO? (default: standard)
5. Micro-architecture of the cycle model: weight-stationary PE mesh with
   internal skew registers (matches the figures) vs. a simpler behavioural
   accumulate-and-drain pipeline with the same latency (faster to write).
