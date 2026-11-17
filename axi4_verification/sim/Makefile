# ==============================================================================
# File: Makefile
# Project: AMBA AXI4 Protocol Verification & VIP Environment
# Description: Universal Makefile for Cadence Xcelium and Siemens QuestaSim
# ==============================================================================

TEST        ?= axi_regression_test
SEED        ?= 1
VERBOSITY   ?= UVM_LOW
COVERAGE    ?= 1

PROJ_DIR    := ..
RTL_DIR     := $(PROJ_DIR)/rtl
TB_DIR      := $(PROJ_DIR)/tb
REPORTS_DIR := $(PROJ_DIR)/reports

INCDIRS     := +incdir+$(RTL_DIR) \
               +incdir+$(TB_DIR)/packages \
               +incdir+$(TB_DIR)/interfaces \
               +incdir+$(TB_DIR)/bfms \
               +incdir+$(TB_DIR)/agents \
               +incdir+$(TB_DIR)/models \
               +incdir+$(TB_DIR)/scoreboard \
               +incdir+$(TB_DIR)/coverage \
               +incdir+$(TB_DIR)/assertions \
               +incdir+$(TB_DIR)/virtual_sequences \
               +incdir+$(TB_DIR)/environment \
               +incdir+$(TB_DIR)/tests \
               +incdir+$(TB_DIR)/top

RTL_FILES   := $(RTL_DIR)/master_top.v

TB_FILES    := $(TB_DIR)/packages/axi_types_pkg.sv \
               $(TB_DIR)/interfaces/axi_interface.sv \
               $(TB_DIR)/interfaces/user_interface.sv \
               $(TB_DIR)/packages/axi_vip_pkg.sv \
               $(TB_DIR)/bfms/axi_master_bfm.sv \
               $(TB_DIR)/bfms/axi_slave_bfm.sv \
               $(TB_DIR)/bfms/user_bfm.sv \
               $(TB_DIR)/assertions/axi_protocol_checker.sv \
               $(TB_DIR)/top/tb_top.sv

# ------------------------------------------------------------------------------
# Cadence Xcelium Flow (xrun)
# ------------------------------------------------------------------------------
XRUN_OPTS   := -64bit -sv -uvm -timescale 1ns/1ps -access +rwc -ALLOWREDEFINITION
XRUN_COV    := -coverage all -covoverwrite -covworkdir $(REPORTS_DIR)/coverage

xrun-compile:
	@mkdir -p $(REPORTS_DIR)/coverage $(REPORTS_DIR)/assertions
	xrun $(XRUN_OPTS) -compile $(INCDIRS) $(RTL_FILES) $(TB_FILES)

xrun:
	@mkdir -p $(REPORTS_DIR)/coverage $(REPORTS_DIR)/assertions
	-xrun $(XRUN_OPTS) $(INCDIRS) $(RTL_FILES) $(TB_FILES) \
		+UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) -svseed $(SEED) \
		$(if $(filter 1,$(COVERAGE)),$(XRUN_COV),) \
		-l $(REPORTS_DIR)/$(TEST)_seed$(SEED).log

# ------------------------------------------------------------------------------
# Self-Contained UVM Native Coverage (Zero tool dependencies, no IMC required)
# ------------------------------------------------------------------------------
cov-run:
	$(MAKE) xrun TEST=axi_coverage_closure_test

cov-view:
	@cat $(REPORTS_DIR)/coverage_summary.txt

cov-browser:
	firefox $(REPORTS_DIR)/coverage_report.html &

# ------------------------------------------------------------------------------
# Cadence Coverage Analysis (IMC - Integrated Metrics Center)
# ------------------------------------------------------------------------------
COV_RUN ?= $(REPORTS_DIR)/coverage/scope/test_sv1

cov-gui:
	imc -load $(COV_RUN) &

cov-html:
	@mkdir -p $(REPORTS_DIR)/coverage_html
	imc -load $(COV_RUN) -execcmd "report -html -detail -metrics all -all -out $(REPORTS_DIR)/coverage_html; exit"
	@echo "Coverage HTML generated at $(REPORTS_DIR)/coverage_html/index.html"

cov-text:
	imc -load $(COV_RUN) -execcmd "report -summary; exit"

cov-detail:
	imc -load $(COV_RUN) -execcmd "report -detail -metrics all -all -out $(REPORTS_DIR)/coverage_detail.txt; exit"
	@echo "Coverage detail report written to $(REPORTS_DIR)/coverage_detail.txt"

# ------------------------------------------------------------------------------
# Siemens QuestaSim Flow (vlog / vsim)
# ------------------------------------------------------------------------------
vsim:
	@mkdir -p work $(REPORTS_DIR)
	vlib work
	vlog -sv $(INCDIRS) $(RTL_FILES) $(TB_FILES)
	vsim -c -do "run -all; quit -f" tb_top \
		+UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) -sv_seed $(SEED) \
		-l $(REPORTS_DIR)/$(TEST)_seed$(SEED).log

# ------------------------------------------------------------------------------
# Python Automated Regression
# ------------------------------------------------------------------------------
regression:
	python run_regression.py

clean:
	rm -rf work INCA_libs xcelium.d xrun.history *.log *.vcd *.wlf tr_db.dir
	rm -rf $(REPORTS_DIR)/*.log

.PHONY: xrun xrun-compile cov-run cov-view cov-browser cov-gui cov-html cov-text cov-detail vsim regression clean
