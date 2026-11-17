// ============================================================================
// File: user_interface.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: SystemVerilog interface for the user-side streaming & command ports
//              of the AXI4 Master Bridge DUT.
// ============================================================================

`ifndef USER_INTERFACE_SV
`define USER_INTERFACE_SV

interface user_interface #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    input logic clk,
    input logic rst_n
);

    // ------------------------------------------------------------------------
    // User Command Channel
    // ------------------------------------------------------------------------
    logic [ADDR_WIDTH-1:0]     user_start_addr;
    logic [31:0]               user_total_bytes;
    logic                      user_rnw;          // 0 = Write, 1 = Read
    logic [1:0]                user_burst;        // 00=FIXED, 01=INCR, 10=WRAP
    logic                      user_cmd_valid;
    logic                      user_cmd_ready;

    // ------------------------------------------------------------------------
    // User TX Data Channel (Write stream into DUT)
    // ------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0]     user_tx_data;
    logic [(DATA_WIDTH/8)-1:0] user_tx_wstrb;
    logic                      user_tx_valid;
    logic                      user_tx_ready;

    // ------------------------------------------------------------------------
    // User RX Data Channel (Read stream from DUT)
    // ------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0]     user_rx_data;
    logic                      user_rx_valid;
    logic                      user_rx_ready;

    // ------------------------------------------------------------------------
    // Status Flags (From DUT)
    // ------------------------------------------------------------------------
    logic                      write_complete;
    logic                      write_error;
    logic                      read_error;

    // ------------------------------------------------------------------------
    // Monitor Clocking Block (Passive sampling with zero race condition)
    // ------------------------------------------------------------------------
    clocking cb_mon @(posedge clk);
        default input #1step;
        input user_start_addr, user_total_bytes, user_rnw, user_burst, user_cmd_valid, user_cmd_ready;
        input user_tx_data, user_tx_wstrb, user_tx_valid, user_tx_ready;
        input user_rx_data, user_rx_valid, user_rx_ready;
        input write_complete, write_error, read_error;
    endclocking

    modport driver_mp (
        output user_start_addr, user_total_bytes, user_rnw, user_burst, user_cmd_valid,
        input  user_cmd_ready,
        output user_tx_data, user_tx_wstrb, user_tx_valid,
        input  user_tx_ready,
        input  user_rx_data, user_rx_valid,
        output user_rx_ready,
        input  write_complete, write_error, read_error,
        input  clk,
        input  rst_n
    );

    modport monitor_mp (
        clocking cb_mon,
        input clk,
        input rst_n
    );

endinterface : user_interface

`endif // USER_INTERFACE_SV
