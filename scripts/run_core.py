#!/usr/bin/env python3
"""Run the formal core self-tests with an existing Questa/UVM installation.

Exit codes: 0 = verified self-test outcome; 1 = failure; 2 = NOT_RUN.
No installation, download, account change, or simulator-license setup is done.
Questa's precompiled UVM is used by default; --uvm-library adds an explicit -L.
This adapter has not been exercised with Questa in this repository's local
environment. Source packaging or a missing-tool check is not UVM compilation.

Command references (vendor documentation):
https://blogs.sw.siemens.com/verificationhorizons/2011/03/08/using-the-uvm-10-release-with-questa/
https://docs.amd.com/r/2023.1-English/ug900-vivado-logic-simulation/Simulation-Step-Control-Constructs-for-ModelSim-and-Questa-Advanced-Simulator
https://ww1.microchip.com/downloads/aemDocuments/documents/FPGA/swdocs/questasim/questa_sim_ref_2024_2.pdf
"""

import argparse
from collections import Counter
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

from bundle_uvm import ROOT, BundleError, bundle

COUNTS = {
    "inputs": 3, "outputs": 3, "compared": 3, "elements": 17,
    "mismatches": 0, "pending_predictions": 0, "pending_actuals": 0,
}
RULES = {
    "matrix_core_smoke_test": (set(), set(), COUNTS),
    "matrix_core_output_first_test": (set(), set(), COUNTS),
    "matrix_core_snapshot_test": (set(), set(), COUNTS),
    "matrix_core_wrong_result_test": (
        {"MATRIX_MISMATCH", "RESULT_CHECK_FAILED"}, {"MATRIX_MISMATCH", "RESULT_CHECK_FAILED"},
        {**COUNTS, "mismatches": 1},
    ),
    "matrix_core_missing_result_test": (
        {"MATRIX_COUNT", "PENDING_RESULTS"}, {"MATRIX_COUNT", "PENDING_RESULTS"},
        {**COUNTS, "outputs": 2, "compared": 2, "elements": 13, "pending_predictions": 1},
    ),
}
REPORT = re.compile(r"^\s*(?:#\s*)?(UVM_INFO|UVM_WARNING|UVM_ERROR|UVM_FATAL)\b(?!\s*:).*?\[([^\]]+)\]\s*(.*)$")
SUMMARY = re.compile(r"^\s*(?:#\s*)?UVM_(ERROR|FATAL)\s*:\s*(\d+)\s*$")
SEVERITY = re.compile(r"^\s*(?:#\s*)?UVM_(ERROR|FATAL)\b")
VENDOR_ERROR = re.compile(r"^\s*(?:#\s*)?\*\*\s+(?:Error|Fatal)\b", re.MULTILINE)


def assess_log(text: str, test: str) -> tuple[bool, str]:
    """Conservative contract check; process success is checked separately."""
    required, allowed, expected_counts = RULES[test]
    negative = bool(required)
    reports, summaries = [], {}
    for number, line in enumerate(text.splitlines()):
        summary = SUMMARY.fullmatch(line)
        report = REPORT.fullmatch(line)
        if summary:
            severity, value = summary.groups()
            if severity in summaries:
                return False, "duplicate UVM report summary"
            summaries[severity] = int(value)
        elif report:
            severity, report_id, message = report.groups()
            reports.append((number, severity, report_id, message))
        elif SEVERITY.match(line):
            return False, "unrecognized UVM error/fatal report"
    if VENDOR_ERROR.search(text):
        return False, "simulator error/fatal diagnostic"
    observed_severities = Counter(row[1] for row in reports)
    if summaries != {"ERROR": observed_severities["UVM_ERROR"], "FATAL": observed_severities["UVM_FATAL"]}:
        return False, "missing or inconsistent final UVM error/fatal summary"
    if observed_severities["UVM_FATAL"]:
        return False, "UVM_FATAL is never an expected negative-test result"
    error_ids = {row[2] for row in reports if row[1] == "UVM_ERROR"}
    if error_ids - allowed or required - error_ids:
        return False, f"unexpected or missing error IDs: observed={sorted(error_ids)} required={sorted(required)}"
    expected_marker = "CORE_SELFTEST_FAIL" if negative else "CORE_SELFTEST_PASS"
    forbidden_marker = "CORE_SELFTEST_PASS" if negative else "CORE_SELFTEST_FAIL"
    if any(row[2] == forbidden_marker for row in reports):
        return False, f"unexpected {forbidden_marker}"
    markers = []
    for report_id in ("CORE_FIXTURE_DONE", "CORE_COUNTS", expected_marker):
        found = [row for row in reports if row[2] == report_id]
        if len(found) != 1 or found[0][1] != "UVM_INFO":
            return False, f"expected one UVM_INFO [{report_id}]"
        markers.append(found[0])
    if not markers[0][0] < markers[1][0] < markers[2][0]:
        return False, "completion/count/result markers are out of order"
    pairs = re.findall(r"([a-z_]+)=(\d+)", markers[1][3])
    counts = {key: int(value) for key, value in pairs}
    if len(pairs) != len(expected_counts) or counts != expected_counts:
        return False, f"fixture counts differ: {counts}; expected {expected_counts}"
    return True, "EXPECTED_FAILURE_CAUGHT" if negative else "CORE_PASS"


def command_run(command: list[str], directory: Path, logfile: str, timeout: float) -> tuple[int, str]:
    """Execute an argument list without a shell and retain actual output only."""
    try:
        result = subprocess.run(command, cwd=directory, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True, timeout=timeout, check=False)
        code, output = result.returncode, result.stdout
    except subprocess.TimeoutExpired as error:
        output = error.stdout or ""
        if isinstance(output, bytes):
            output = output.decode(errors="replace")
        code = 124
    (directory / logfile).write_text(output)
    return code, output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--sim", choices=("auto", "questa"), default="auto")
    parser.add_argument("--test", choices=tuple(RULES), default="matrix_core_smoke_test")
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--timeout", type=float, default=120, help="wall-clock seconds per subprocess")
    parser.add_argument("--uvm-library", help="installed precompiled UVM library name or absolute path")
    args = parser.parse_args()
    if not 1 <= args.seed <= 2147483647 or args.timeout <= 0:
        parser.error("seed must be 1..2147483647 and timeout must be positive")
    executables = {name: shutil.which(name) for name in ("vlib", "vlog", "vsim")}
    missing = [name for name, path in executables.items() if path is None]
    if missing:
        print(f"NOT_RUN: Questa tools unavailable: {', '.join(missing)}. UVM was not compiled or simulated.", file=sys.stderr)
        return 2
    try:
        content, sources = bundle()
        build = ROOT / "build/core"
        build.mkdir(parents=True, exist_ok=True)
        run_dir = Path(tempfile.mkdtemp(prefix=args.test + "-", dir=build))
        (run_dir / "core_bundle.sv").write_text(content)
        library = ["-L", args.uvm_library] if args.uvm_library else []
        commands = [
            ("library", [executables["vlib"], "work"]),
            ("compile", [executables["vlog"], "-sv", *library, "core_bundle.sv"]),
            ("simulate", [executables["vsim"], "-c", *library, "-sv_seed", str(args.seed),
                          "work.matrix_core_tb", "+UVM_TESTNAME=" + args.test,
                          "-do", "onerror {quit -f -code 1}; run -all; quit -f"]),
        ]
        record = {"test": args.test, "seed": args.seed, "simulator": "questa",
                  "status": "STARTED", "sources": sources, "commands": commands}
        for phase, command in commands:
            code, output = command_run(command, run_dir, phase + ".log", args.timeout)
            if code != 0 or VENDOR_ERROR.search(output):
                record.update(status="FAIL", phase=phase, returncode=code)
                break
        else:
            passed, reason = assess_log(output, args.test)
            record.update(status="PASS" if passed else "FAIL", reason=reason)
        (run_dir / "result.json").write_text(json.dumps(record, indent=2) + "\n")
        print(f"{record['status']}: {args.test}; logs: {run_dir}")
        if "reason" in record:
            print(record["reason"])
        return 0 if record["status"] == "PASS" else 1
    except (BundleError, OSError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
