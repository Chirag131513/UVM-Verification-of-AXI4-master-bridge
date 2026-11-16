# ==============================================================================
# File: run.tcl
# Project: AMBA AXI4 Protocol Verification & VIP Environment
# Tool: Simulation Execution script with waveform dump and coverage
# ==============================================================================

# Default parameters if not supplied by command line
if {![info exists TESTNAME]} {
    set TESTNAME "axi_directed_test"
}
if {![info exists SEED]} {
    set SEED 1
}
if {![info exists VERBOSITY]} {
    set VERBOSITY "UVM_LOW"
}

puts "\[INFO\] Running Test: $TESTNAME with Seed: $SEED, Verbosity: $VERBOSITY"

# Run simulation to completion
run -all

# Exit
quit -f
