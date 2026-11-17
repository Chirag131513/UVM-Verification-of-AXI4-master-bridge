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
    logic [ID_WIDTH-1:0]       awid    = '0;
    logic [ADDR_WIDTH-1:0]     awaddr  = '0;
    logic [7:0]                awlen   = '0;
    logic [2:0]                awsize  = '0;
    logic [1:0]                awburst = '0;
    logic [3:0]                awcache = '0;
    logic [2:0]                awprot  = '0;
    logic                      awvalid = 1'b0;
    logic                      awready = 1'b0;

    // ------------------------------------------------------------------------
    // Write Data Channel (W)
    // ------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0]     wdata   = '0;
    logic [(DATA_WIDTH/8)-1:0] wstrb   = '0;
    logic                      wlast   = 1'b0;
    logic                      wvalid  = 1'b0;
    logic                      wready  = 1'b0;

    // ------------------------------------------------------------------------
    // Write Response Channel (B)
    // ------------------------------------------------------------------------
    logic [ID_WIDTH-1:0]       bid     = '0;
    logic [1:0]                bresp   = '0;
    logic                      bvalid  = 1'b0;
    logic                      bready  = 1'b0;

    // ------------------------------------------------------------------------
    // Read Address Channel (AR)
    // ------------------------------------------------------------------------
    logic [ID_WIDTH-1:0]       arid    = '0;
    logic [ADDR_WIDTH-1:0]     araddr  = '0;
    logic [7:0]                arlen   = '0;
    logic [2:0]                arsize  = '0;
    logic [1:0]                arburst = '0;
    logic [3:0]                arcache = '0;
    logic [2:0]                arprot  = '0;
    logic                      arvalid = 1'b0;
    logic                      arready = 1'b0;

    // ------------------------------------------------------------------------
    // Read Data Channel (R)
    // ------------------------------------------------------------------------
    logic [ID_WIDTH-1:0]       rid     = '0;
    logic [DATA_WIDTH-1:0]     rdata   = '0;
    logic [1:0]                rresp   = '0;
    logic                      rlast   = 1'b0;
    logic                      rvalid  = 1'b0;
    logic                      rready  = 1'b0;

    // ------------------------------------------------------------------------
    // Clocking Blocks
    // ------------------------------------------------------------------------
    
    // ------------------------------------------------------------------------
    // Monitor Clocking Block (Passive sampling with zero race condition)
    // ------------------------------------------------------------------------
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
        output awid, awaddr, awlen, awsize, awburst, awcache, awprot, awvalid,
        input  awready,
        output wdata, wstrb, wlast, wvalid,
        input  wready,
        input  bid, bresp, bvalid,
        output bready,
        output arid, araddr, arlen, arsize, arburst, arcache, arprot, arvalid,
        input  arready,
        input  rid, rdata, rresp, rlast, rvalid,
        output rready,
        input  ACLK,
        input  ARESETn
    );

    modport slave_mp (
        input  awid, awaddr, awlen, awsize, awburst, awcache, awprot, awvalid,
        output awready,
        input  wdata, wstrb, wlast, wvalid,
        output wready,
        output bid, bresp, bvalid,
        input  bready,
        input  arid, araddr, arlen, arsize, arburst, arcache, arprot, arvalid,
        output arready,
        output rid, rdata, rresp, rlast, rvalid,
        input  rready,
        input  ACLK,
        input  ARESETn
    );

    modport monitor_mp (
        clocking cb_mon,
        input ACLK,
        input ARESETn
    );

endinterface : axi_interface

`endif // AXI_INTERFACE_SV
