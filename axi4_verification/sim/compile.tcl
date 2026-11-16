# ==============================================================================
# File: compile.tcl
# Project: AMBA AXI4 Protocol Verification & VIP Environment
# Tool: Cadence Xcelium (xrun) / Siemens QuestaSim (vlog) compilation script
# ==============================================================================

# Directories
set PROJ_DIR ".."
set RTL_DIR  "$PROJ_DIR/rtl"
set TB_DIR   "$PROJ_DIR/tb"

# Include paths
set INC_DIRS "+incdir+$RTL_DIR \
              +incdir+$TB_DIR/packages \
              +incdir+$TB_DIR/interfaces \
              +incdir+$TB_DIR/bfms \
              +incdir+$TB_DIR/agents \
              +incdir+$TB_DIR/models \
              +incdir+$TB_DIR/scoreboard \
              +incdir+$TB_DIR/coverage \
              +incdir+$TB_DIR/assertions \
              +incdir+$TB_DIR/virtual_sequences \
              +incdir+$TB_DIR/environment \
              +incdir+$TB_DIR/tests \
              +incdir+$TB_DIR/top"

# RTL Source Files
set RTL_SRCS "$RTL_DIR/sync_fifo.v \
              $RTL_DIR/read_issuer.v \
              $RTL_DIR/data_issuer.v \
              $RTL_DIR/data_resposer.v \
              $RTL_DIR/addr_splitter.v \
              $RTL_DIR/addr_issuer.v \
              $RTL_DIR/master_top.v"

# Testbench Packages and Interfaces
set TB_SRCS "$TB_DIR/packages/axi_types_pkg.sv \
             $TB_DIR/packages/axi_vip_pkg.sv \
             $TB_DIR/interfaces/axi_interface.sv \
             $TB_DIR/interfaces/user_interface.sv \
             $TB_DIR/bfms/axi_master_bfm.sv \
             $TB_DIR/bfms/axi_slave_bfm.sv \
             $TB_DIR/bfms/user_bfm.sv \
             $TB_DIR/assertions/axi_protocol_checker.sv \
             $TB_DIR/top/tb_top.sv"

puts "\[INFO\] AMBA AXI4 Verification VIP: Compiling RTL and UVM Testbench..."
