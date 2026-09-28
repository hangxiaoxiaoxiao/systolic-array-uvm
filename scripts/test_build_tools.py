#!/usr/bin/env python3
"""Unit tests of Python packaging/log parsing, NOT UVM simulation.

All report strings below are synthetic parser inputs; none are written as
simulator logs or presented as hardware/self-test execution evidence.
"""

from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from bundle_uvm import BundleError, CORE_SOURCES, INCLUDE_DIRS, bundle
from run_core import RULES, assess_log
import run_core


def parser_input(test):
    required, _, counts = RULES[test]
    lines = [f"# UVM_ERROR synthetic.sv(1) @ 0: fixture [{report_id}] injected parser input"
             for report_id in sorted(required)]
    lines.append("# UVM_INFO synthetic.sv(2) @ 0: fixture [CORE_FIXTURE_DONE] all scheduled publications completed")
    lines.append("# UVM_INFO synthetic.sv(3) @ 0: fixture [CORE_COUNTS] " +
                 " ".join(f"{key}={value}" for key, value in counts.items()))
    marker = "CORE_SELFTEST_FAIL" if required else "CORE_SELFTEST_PASS"
    lines.append(f"# UVM_INFO synthetic.sv(4) @ 0: fixture [{marker}] parser fixture")
    lines.extend([f"# UVM_ERROR : {len(required)}", "# UVM_FATAL : 0"])
    return "\n".join(lines)


class LogParserTests(unittest.TestCase):
    def test_all_five_contracts(self):
        for test in RULES:
            with self.subTest(test=test):
                self.assertTrue(assess_log(parser_input(test), test)[0])

    def test_rejects_incomplete_unexpected_or_counterfeit_outcomes(self):
        test = "matrix_core_smoke_test"
        valid = parser_input(test)
        invalid = {
            "empty": "",
            "missing pass": valid.replace("CORE_SELFTEST_PASS", "UNRELATED_ID"),
            "wrong marker": valid.replace("CORE_SELFTEST_PASS", "CORE_SELFTEST_FAIL"),
            "missing completion": valid.replace("CORE_FIXTURE_DONE", "UNRELATED_ID"),
            "wrong count": valid.replace("elements=17", "elements=16"),
            "extra count": valid.replace("elements=17", "elements=17 extra=1"),
            "duplicate marker": valid + "\n" + valid.splitlines()[2],
            "no summary": "\n".join(valid.splitlines()[:-2]),
            "inconsistent summary": valid.replace("UVM_ERROR : 0", "UVM_ERROR : 1"),
            "compiler error": valid + "\n# ** Error: compilation failed",
            "unknown error": valid + "\n# UVM_ERROR fixture(1) @ 0: test [OTHER] bad",
            "fatal": valid.replace("UVM_FATAL : 0", "UVM_FATAL : 1") +
                     "\n# UVM_FATAL fixture(1) @ 0: test [BOOM] bad",
            "malformed severity": valid + "\nUVM_ERROR an unrecognized report",
            "source text": 'source line: `uvm_info("CORE_SELFTEST_PASS", "ok", UVM_NONE)',
            "out of order": "\n".join([valid.splitlines()[1], valid.splitlines()[0], *valid.splitlines()[2:]]),
        }
        for name, text in invalid.items():
            with self.subTest(case=name):
                self.assertFalse(assess_log(text, test)[0])

    def test_negative_requires_specific_reports_and_fail_marker(self):
        for test in ("matrix_core_wrong_result_test", "matrix_core_missing_result_test"):
            valid = parser_input(test)
            required = RULES[test][0]
            for report_id in required:
                self.assertFalse(assess_log(valid.replace(report_id, "UNRELATED_ID"), test)[0])
            self.assertFalse(assess_log(valid.replace("CORE_SELFTEST_FAIL", "CORE_SELFTEST_PASS"), test)[0])
            self.assertFalse(assess_log("** Error: compile failed", test)[0])

    def test_wrong_result_requires_final_result_check_failed_report(self):
        test = "matrix_core_wrong_result_test"
        valid = parser_input(test)
        self.assertIn("[RESULT_CHECK_FAILED]", valid)
        self.assertTrue(assess_log(valid, test)[0])
        missing_final_report = "\n".join(
            line for line in valid.splitlines() if "[RESULT_CHECK_FAILED]" not in line
        ).replace("UVM_ERROR : 2", "UVM_ERROR : 1")
        # Keep the summary consistent so the missing report ID must cause failure.
        passed, reason = assess_log(missing_final_report, test)
        self.assertFalse(passed)
        self.assertIn("missing error IDs", reason)


class BundleTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name).resolve()
        (self.root / "sim").mkdir()
        for source in CORE_SOURCES:
            target = self.root / source
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("// synthetic source for Python unit test\n")
        (self.root / CORE_SOURCES[2]).write_text("module matrix_core_tb; endmodule\n")
        (self.root / "sim/core.f").write_text("\n".join(
            [f"+incdir+{name}" for name in INCLUDE_DIRS] + list(CORE_SOURCES)))
        (self.root / CORE_SOURCES[0]).write_text('`include "uvm_macros.svh"\n`include "item.svh"\n')
        (self.root / "tb/common/item.svh").write_text("class matrix_item; endclass\n")

    def tearDown(self):
        self.temporary.cleanup()

    def test_preserves_uvm_expands_only_explicit_repository_header(self):
        (self.root / "lessons").mkdir()
        (self.root / "lessons/old.sv").write_text("OBSOLETE_LESSON_MUST_NOT_APPEAR")
        text, used = bundle(self.root)
        self.assertIn('`include "uvm_macros.svh"', text)
        self.assertNotIn('`include "item.svh"', text)
        self.assertIn("class matrix_item", text)
        self.assertNotIn("OBSOLETE_LESSON_MUST_NOT_APPEAR", text)
        self.assertEqual(len(used), 4)

    def test_rejects_unresolved_recursive_and_nonliteral_includes(self):
        for content in ('`include "missing.svh"\n', '`include "item.svh"\n',
                        '`include SOME_MACRO\n', '`include "../../lessons/old.svh"\n'):
            with self.subTest(include=content):
                (self.root / "tb/common/item.svh").write_text(content)
                with self.assertRaises(BundleError):
                    bundle(self.root)

    def test_rejects_external_symlink_and_extra_manifest_source(self):
        (self.root / "outside.svh").write_text("// outside allowed formal source directories\n")
        header = self.root / "tb/common/item.svh"
        header.unlink()
        header.symlink_to(self.root / "outside.svh")
        with self.assertRaises(BundleError):
            bundle(self.root)
        (self.root / "sim/core.f").write_text("lessons/01_matrix_ref_demo.sv\n")
        with self.assertRaises(BundleError):
            bundle(self.root)


class RunnerTests(unittest.TestCase):
    def test_missing_simulator_is_not_run(self):
        with patch.object(run_core.shutil, "which", return_value=None), \
                patch("sys.argv", ["run_core.py"]), \
                patch("builtins.print"):
            self.assertEqual(run_core.main(), 2)

    def test_compile_error_cannot_pass_negative_test(self):
        with tempfile.TemporaryDirectory() as temporary:
            with patch.object(run_core, "ROOT", Path(temporary)), \
                    patch.object(run_core, "bundle", return_value=("// synthetic stub", [])), \
                    patch.object(run_core.shutil, "which", side_effect=lambda name: "/synthetic/" + name), \
                    patch.object(run_core, "command_run", side_effect=[(0, ""), (1, "compile failed")]) as command, \
                    patch("sys.argv", ["run_core.py", "--test", "matrix_core_wrong_result_test"]), \
                    patch("builtins.print"):
                self.assertEqual(run_core.main(), 1)
                self.assertEqual(command.call_count, 2)


if __name__ == "__main__":
    unittest.main()
