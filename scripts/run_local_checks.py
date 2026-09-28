#!/usr/bin/env python3
"""Run eight ordinary-SystemVerilog baseline checks with existing Icarus tools.

This exercises lessons 46 and 58, not tb/common, UVM, or interview RTL.
Exit codes: 0 = all eight expected outcomes observed; 1 = failed check;
2 = NOT_RUN because a requested tool is unavailable. Nothing is installed.
Actual commands/logs and the latest run.json are saved under
sim/results/local-baseline; historical lesson logs are never modified.
"""

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "sim/results/local-baseline"
LABEL = "ordinary-SystemVerilog baseline only, not formal UVM core"
REFERENCE_TOP = "parameterized_reference_demo"
OUTPUT_TOP = "output_reconstruction_demo"
CASE_NAMES = ("zero", "sparse_last_term", "positive_endpoints", "negative_endpoints")
NORMAL_COUNTS = {
    "input_frames": 1, "reference_calls": 1, "output_words": 2,
    "assembled_rows": 2, "compared_matrices": 1, "compared_elements": 4,
    "mismatches": 0, "pending": 0, "source_done": 1, "errors": 0,
}
MISSING_COUNTS = {
    **NORMAL_COUNTS, "output_words": 1, "assembled_rows": 1,
    "compared_matrices": 0, "compared_elements": 0, "pending": 1, "errors": 3,
}


def cases() -> list[dict]:
    result = [
        {"name": f"reference_w{w}_n{n}_m{m}", "kind": "reference",
         "parameters": {"DIN_WIDTH": w, "N": n, "M": m}, "plusargs": []}
        for w, n, m in ((8, 2, 3), (4, 3, 2), (8, 2, 1))
    ]
    result.append({"name": "reference_unknown", "kind": "reference",
                   "parameters": {"DIN_WIDTH": 8, "N": 2, "M": 3},
                   "plusargs": ["+INJECT_UNKNOWN"]})
    for name, plusargs in (
        ("normal", []),
        ("wrong", ["+INJECT_RESULT_ERROR"]),
        ("missing", ["+DROP_LAST_ROW"]),
        ("combined", ["+INJECT_RESULT_ERROR", "+DROP_LAST_ROW"]),
    ):
        result.append({"name": "output_" + name, "kind": "output",
                       "parameters": {}, "plusargs": plusargs})
    return result


def save_json(path: Path, value: dict) -> None:
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def command_run(command: list[str], logfile: Path, timeout: float) -> tuple[dict, str]:
    """No shell: retain the exact argument list and combined tool output."""
    record = {"argv": command, "cwd": str(ROOT), "log": str(logfile.relative_to(ROOT))}
    try:
        process = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, text=True, encoding="utf-8",
                                 errors="replace", timeout=timeout, check=False)
        output = process.stdout
        record.update(returncode=process.returncode, timed_out=False)
    except subprocess.TimeoutExpired as error:
        output = error.stdout or ""
        if isinstance(output, bytes):
            output = output.decode("utf-8", errors="replace")
        record.update(returncode=None, timed_out=True)
    except OSError as error:
        output = ""
        record.update(returncode=None, timed_out=False, launch_error=str(error))
    logfile.write_text(output, encoding="utf-8")
    return record, output


def assess(case: dict, returncode: int | None, output: str) -> tuple[bool, str]:
    """Check the intended result, not merely a nonzero negative-test exit code."""
    negative = bool(case["plusargs"])
    if returncode != (1 if negative else 0):
        return False, f"unexpected simulator return code {returncode}"
    fatal_lines = re.findall(r"^FATAL:.*$", output, re.MULTILINE)
    if negative:
        if "PASS" in output:
            return False, "negative test emitted a PASS marker"
        if len(fatal_lines) != 1:
            return False, "expected exactly one simulation FATAL diagnostic"
    elif fatal_lines:
        return False, "positive test emitted a FATAL diagnostic"

    if case["kind"] == "reference":
        w, n, m = (case["parameters"][key] for key in ("DIN_WIDTH", "N", "M"))
        expected_parameters = (
            f"PARAMETERS: DIN_WIDTH={w} N={n} M={m} PRODUCT_WIDTH={2*w} "
            f"ACC_WIDTH={2*w + (m-1).bit_length()}"
        )
        if output.splitlines().count(expected_parameters) != 1:
            return False, "missing or incorrect reference parameter/width report"
        if negative:
            if "UNKNOWN_INPUT: A[0][0] contains X/Z" not in fatal_lines[0]:
                return False, "expected UNKNOWN_INPUT fatal for A[0][0]"
        else:
            passed_cases = re.findall(r"^CASE_PASS: ([a-z_]+), elements=(\d+),", output, re.MULTILINE)
            if passed_cases != [(name, str(n*n)) for name in CASE_NAMES]:
                return False, "reference cases or element counts differ"
            final = (f"PARAMETERIZED_REFERENCE_PASS: {4*n*n} exact sums and range flags matched; "
                     "no DUT checked.")
            if output.splitlines().count(final) != 1:
                return False, "missing or incorrect final reference result"
    else:
        name = case["name"].removeprefix("output_")
        expected_counts = (MISSING_COUNTS if name in ("missing", "combined") else
                           {**NORMAL_COUNTS, "mismatches": 1, "errors": 1}
                           if name == "wrong" else NORMAL_COUNTS)
        state_lines = re.findall(r"^COMPLETION_STATE: (.*)$", output, re.MULTILINE)
        if len(state_lines) != 1:
            return False, "expected one final completion state"
        pairs = re.findall(r"([a-z_]+)=(\d+)", state_lines[0])
        observed = {key: int(value) for key, value in pairs}
        if len(pairs) != len(expected_counts) or observed != expected_counts:
            return False, f"completion counters differ: {observed}; expected {expected_counts}"
        mismatch_lines = re.findall(r"^RESULT_MISMATCH:.*$", output, re.MULTILINE)
        if name == "wrong":
            if mismatch_lines != ["RESULT_MISMATCH: C[1][0] sampled=-82 expected=-83"]:
                return False, "wrong-result diagnostic did not identify the injected element"
            if "VALUE_MISMATCHES: 1 numerical mismatches" not in output.splitlines():
                return False, "missing numerical mismatch summary"
        elif mismatch_lines:
            return False, "unexpected numerical mismatch"
        if name in ("missing", "combined"):
            for marker in (
                "OUTPUT_WORD_COUNT: input_frames=1 words=1 expected_words=2",
                "MATRIX_COUNT: input_frames=1 compared_matrices=0",
                "PENDING_RESULT: one prediction still has no compared result",
            ):
                if output.splitlines().count(marker) != 1:
                    return False, f"missing expected diagnostic: {marker}"
        if name == "combined" and "DROP_PRECEDENCE:" not in output:
            return False, "combined test did not report missing-row precedence"
        if negative:
            if f"COMPLETION_FAILED: {expected_counts['errors']} failed completion checks" not in fatal_lines[0]:
                return False, "unexpected completion fatal"
        elif output.splitlines().count(
            "OUTPUT_RECONSTRUCTION_PASS: one result sampled and compared; independent fixture, no interview RTL checked."
        ) != 1:
            return False, "missing final output reconstruction result"
    return True, "EXPECTED_FAILURE_CAUGHT" if negative else "PASS"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--iverilog", default="iverilog", help="executable name on PATH or executable path")
    parser.add_argument("--vvp", default="vvp", help="executable name on PATH or executable path")
    parser.add_argument("--timeout", type=float, default=30, help="seconds allowed per compiler/simulator subprocess")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")

    RESULTS.mkdir(parents=True, exist_ok=True)
    selected = {"iverilog": shutil.which(args.iverilog), "vvp": shutil.which(args.vvp)}
    # Resolve caller-relative paths before subprocesses change cwd to ROOT.
    selected = {name: str(Path(path).resolve()) if path else None for name, path in selected.items()}
    record = {"label": LABEL, "formal_uvm_core_executed": False,
              "started_at": datetime.now(timezone.utc).isoformat(),
              "tools": selected, "cases": cases(), "status": "STARTED"}
    missing = [name for name, path in selected.items() if path is None]
    if missing:
        record.update(status="NOT_RUN", reason="Unavailable tools: " + ", ".join(missing))
        for case in record["cases"]:
            case.update(status="NOT_RUN", commands=[])
        save_json(RESULTS / "run.json", record)
        print("NOT_RUN: " + record["reason"] + ". No simulator was run.", file=sys.stderr)
        return 2

    run_dir = Path(tempfile.mkdtemp(prefix="run-", dir=RESULTS))
    record["run_directory"] = str(run_dir.relative_to(ROOT))
    for case in record["cases"]:
        case_dir = run_dir / case["name"]
        case_dir.mkdir()
        top = REFERENCE_TOP if case["kind"] == "reference" else OUTPUT_TOP
        source = "lessons/46_parameterized_reference.sv" if case["kind"] == "reference" else "lessons/58_output_reconstruction.sv"
        executable = case_dir / "simulation.vvp"
        compile_command = [selected["iverilog"], "-g2012", "-s", top,
                           *[f"-P{top}.{key}={value}" for key, value in case["parameters"].items()],
                           "-o", str(executable), source]
        compile_record, _ = command_run(compile_command, case_dir / "compile.log", args.timeout)
        case["commands"] = {"compile": compile_record}
        if compile_record["returncode"] != 0 or not executable.is_file():
            case.update(status="FAIL", reason="Compilation failed; simulation was not attempted")
        else:
            command = [selected["vvp"], str(executable), *case["plusargs"]]
            simulation_record, output = command_run(command, case_dir / "simulation.log", args.timeout)
            case["commands"]["simulate"] = simulation_record
            passed, reason = assess(case, simulation_record["returncode"], output)
            case.update(status=reason if passed else "FAIL", reason=reason)
        save_json(case_dir / "result.json", case)
        print(f"{case['status']}: {case['name']}" + (f"; {case['reason']}" if case["status"] == "FAIL" else ""))

    record["verified_cases"] = sum(case["status"] in ("PASS", "EXPECTED_FAILURE_CAUGHT") for case in record["cases"])
    record["status"] = "PASS" if record["verified_cases"] == 8 else "FAIL"
    record["finished_at"] = datetime.now(timezone.utc).isoformat()
    save_json(run_dir / "run.json", record)
    save_json(RESULTS / "run.json", record)
    print(f"{record['status']}: {record['verified_cases']}/8 expected outcomes; {LABEL}")
    print(f"Evidence: {RESULTS / 'run.json'}")
    return 0 if record["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
