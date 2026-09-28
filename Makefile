PYTHON ?= python3
TEST ?= matrix_core_smoke_test
SIM ?= auto
SEED ?= 1
TIMEOUT ?= 120
UVM_LIBRARY ?=

.PHONY: help source-check bundle tools-test local-check core

help:
	@echo "source-check : validate source manifest/includes; no SV compilation"
	@echo "bundle       : generate build/core_bundle.sv"
	@echo "tools-test   : run Python build/log-parser tests"
	@echo "local-check  : run ordinary SV baselines using existing Icarus/VVP"
	@echo "core         : run a core UVM test with existing Questa/UVM tools"
	@echo "Options: TEST=<class> SIM=auto|questa SEED=1 TIMEOUT=120 UVM_LIBRARY=<library>"

source-check:
	$(PYTHON) scripts/bundle_uvm.py --check

bundle:
	$(PYTHON) scripts/bundle_uvm.py

tools-test:
	$(PYTHON) scripts/test_build_tools.py -v

local-check:
	$(PYTHON) scripts/run_local_checks.py

core:
	$(PYTHON) scripts/run_core.py --sim "$(SIM)" --test "$(TEST)" --seed "$(SEED)" --timeout "$(TIMEOUT)" $(if $(UVM_LIBRARY),--uvm-library "$(UVM_LIBRARY)",)
