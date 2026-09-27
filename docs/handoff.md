# Session handoff (2026-09-26)

Context for whoever (or whichever Claude / Codex session) picks this
repository up next.

## What exists

* `README.md` — project summary and roadmap (Chinese).
* `docs/verification-plan.md` — discussion-stage verification plan (Chinese):
  requirements, environment structure, test scope, implementation order,
  pass criteria.
* `docs/spec-questions.md` — the P0/P1 list of interface questions the
  assignment leaves open.
* `docs/dv-architecture-and-assumptions.md` — proposed default answer for
  every open question (assumptions A1–A13), the two-level UVM architecture and
  reuse strategy, checkers, test list, functional coverage, tooling, and the
  five decisions still to be made (section 8).

Nothing has been implemented yet; the documents are the discussion anchor.

## Decisions proposed (not yet frozen)

* No RTL is provided, so a cycle-accurate SystemVerilog model of both DUT
  levels is written by us and used as the simulation target (`rtl_model/`).
  Its pass results are evidence about the model under the stated assumptions,
  not about the real RTL — say so in the final documentation.
* One `matmul_item` transaction shared by both levels; the module-level
  `sa_agent` is reused in passive mode at the sub-system level via `bind`.
* Parameterisation through `MAX_N` / `MAX_DIN_WIDTH`-sized interfaces plus a
  config object; clock periods via plusargs; `N` / `DIN_WIDTH` swept by a
  regression script.
* The assignment PDF is confidential and stays out of the repository
  (`*.pdf` is ignored). The repository is private.

## Housekeeping to fix early

* `.gitignore` currently ignores `*.log` and `sim/results/`, but simulation
  logs and waveform screenshots are deliverables. Add a `results/` directory
  with an un-ignore rule (`!results/**`) before the first run is archived.

## Next steps

1. Settle the five open questions in
   `docs/dv-architecture-and-assumptions.md` §8 (A3 skew, A5 `c_din`, A6 wrap
   vs. saturate, A8 FIFO type, model micro-architecture) and freeze the
   assumptions; record the answers in `docs/spec-questions.md`.
2. `tb/common`: parameter package, `matmul_item`, reference model,
   pack/unpack helpers.
3. `rtl_model/systolic_array.sv` (cycle-accurate), then `sub_sys.sv`
   (dual-clock FIFOs + controller + alignment + array instance).
4. Module-level env and tests; sub-system env and tests; regression script;
   EDA Playground bundle; logs and waveform screenshots into `results/`.
