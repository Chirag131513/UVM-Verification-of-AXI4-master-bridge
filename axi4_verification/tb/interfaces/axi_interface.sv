// ============================================================================
// File: axi_interface.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Fully parameterizable SystemVerilog interface for all 5 AXI4 channels
//              with dedicated master, slave, and monitor clocking blocks.
// ============================================================================

`ifndef AXI_INTERFACE_SV
`define AXI_INTERFACE_SV

interface axi_interface #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4
)(
    input logic ACLK,
    input logic ARESETn
);

    // ------------------------------------------------------------------------
    // Write Address Channel (AW)
    // ------------------------------------------------------------------------
    logic [ID_WIDTH-1:0]       awid;
    logic [ADDR_WIDTH-1:0]     awaddr;
    logic [7:0]                awlen;
    logic [2:0]                awsize;
    logic [1:0]                awburst;
    logic [3:0]                awcache;
    logic [2:0]                awprot;
    logic                      awvalid;
    logic                      awready;

    // ------------------------------------------------------------------------
    // Write Data Channel (W)
    // ------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0]     wdata;
    logic [(DATA_WIDTH/8)-1:0] wstrb;
    logic                      wlast;
    logic                      wvalid;
    logic                      wready;

    // ------------------------------------------------------------------------
    // Write Response Channel (B)
    // ------------------------------------------------------------------------
    logic [ID_WIDTH-1:0]       bid;
    logic [1:0]                bresp;
    logic                      bvalid;
    logic                      bready;

    // ------------------------------------------------------------------------
    // Read Address Channel (AR)
    // ------------------------------------------------------------------------
    logic [ID_WIDTH-1:0]       arid;
    logic [ADDR_WIDTH-1:0]     araddr;
    logic [7:0]                arlen;
    logic [2:0]                arsize;
    logic [1:0]                arburst;
    logic [3:0]                arcache;
    logic [2:0]                arprot;
    logic                      arvalid;
    logic                      arready;

    // ------------------------------------------------------------------------
    // Read Data Channel (R)
    // ------------------------------------------------------------------------
    logic [ID_WIDTH-1:0]       rid;
    logic [DATA_WIDTH-1:0]     rdata;
    logic [1:0]                rresp;
    logic                      rlast;
    logic                      rvalid;
    logic                      rready;

    // ------------------------------------------------------------------------
    // Clocking Blocks
    // ------------------------------------------------------------------------
    
    // Master Clocking Block (Active VIP Master driving bus)
    clocking cb_master @(posedge ACLK);
        default input #1step output #1ns;
        output awid, awaddr, awlen, awsize, awburst, awcache, awprot, awvalid;
        input  awready;
        output wdata, wstrb, wlast, wvalid;
        input  wready;
        input  bid, bresp, bvalid;
        output bready;
        output arid, araddr, arlen, arsize, arburst, arcache, arprot, arvalid;
        input  arready;
        input  rid, rdata, rresp, rlast, rvalid;
        output rready;
    endclocking

    // Slave Clocking Block (Active VIP Slave responding to Master DUT)
    clocking cb_slave @(posedge ACLK);
        default input #1step output #1ns;
        input  awid, awaddr, awlen, awsize, awburst, awcache, awprot, awvalid;
        output awready;
        input  wdata, wstrb, wlast, wvalid;
        output wready;
        output bid, bresp, bvalid;
        input  bready;
        input  arid, araddr, arlen, arsize, arburst, arcache, arprot, arvalid;
        output arready;
        output rid, rdata, rresp, rlast, rvalid;
        input  rready;
    endclocking

    // Monitor Clocking Block (Passive sampling with zero race condition)
    clocking cb_mon @(posedge ACLK);
        default input #1step;
        input awid, awaddr, awlen, awsize, awburst, awcache, awprot, awvalid, awready;
        input wdata, wstrb, wlast, wvalid, wready;
        input bid, bresp, bvalid, bready;
        input arid, araddr, arlen, arsize, arburst, arcache, arprot, arvalid, arready;
        input rid, rdata, rresp, rlast, rvalid, rready;
    endclocking

    // ------------------------------------------------------------------------
    // Modports
    // ------------------------------------------------------------------------
    modport master_mp (
        clocking cb_master,
        input ACLK,
        input ARESETn
    );

    modport slave_mp (
        clocking cb_slave,
        input ACLK,
        input ARESETn
    );

    modport monitor_mp (
        clocking cb_mon,
        input ACLK,
        input ARESETn
    );

endinterface : axi_interface

`endif // AXI_INTERFACE_SV
