// ============================================================================
// File: axi_master_bfm.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Mailbox-synchronized Bus Functional Model (BFM) for AXI4 Master.
//              Supports both Active (VIP drives bus) and Passive (VIP monitors bus)
//              modes, preventing multi-driver conflicts with Master DUT.
// ============================================================================

`ifndef AXI_MASTER_BFM_SV
`define AXI_MASTER_BFM_SV

interface axi_master_bfm #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4,
    parameter bit IS_ACTIVE  = 1'b0  // 0 = Passive Monitor for Master Bridge DUT, 1 = Active
)(
    input logic ACLK,
    input logic ARESETn,

    // AXI Bus Signals
    input  logic [ID_WIDTH-1:0]       awid_in,
    output logic [ID_WIDTH-1:0]       awid_out,
    input  logic [ADDR_WIDTH-1:0]     awaddr_in,
    output logic [ADDR_WIDTH-1:0]     awaddr_out,
    input  logic [7:0]                awlen_in,
    output logic [7:0]                awlen_out,
    input  logic [2:0]                awsize_in,
    output logic [2:0]                awsize_out,
    input  logic [1:0]                awburst_in,
    output logic [1:0]                awburst_out,
    input  logic [3:0]                awcache_in,
    output logic [3:0]                awcache_out,
    input  logic [2:0]                awprot_in,
    output logic [2:0]                awprot_out,
    input  logic                      awvalid_in,
    output logic                      awvalid_out,
    input  logic                      awready,

    input  logic [DATA_WIDTH-1:0]     wdata_in,
    output logic [DATA_WIDTH-1:0]     wdata_out,
    input  logic [(DATA_WIDTH/8)-1:0] wstrb_in,
    output logic [(DATA_WIDTH/8)-1:0] wstrb_out,
    input  logic                      wlast_in,
    output logic                      wlast_out,
    input  logic                      wvalid_in,
    output logic                      wvalid_out,
    input  logic                      wready,

    input  logic [ID_WIDTH-1:0]       bid,
    input  logic [1:0]                bresp,
    input  logic                      bvalid,
    input  logic                      bready_in,
    output logic                      bready_out,

    input  logic [ID_WIDTH-1:0]       arid_in,
    output logic [ID_WIDTH-1:0]       arid_out,
    input  logic [ADDR_WIDTH-1:0]     araddr_in,
    output logic [ADDR_WIDTH-1:0]     araddr_out,
    input  logic [7:0]                arlen_in,
    output logic [7:0]                arlen_out,
    input  logic [2:0]                arsize_in,
    output logic [2:0]                arsize_out,
    input  logic [1:0]                arburst_in,
    output logic [1:0]                arburst_out,
    input  logic [3:0]                arcache_in,
    output logic [3:0]                arcache_out,
    input  logic [2:0]                arprot_in,
    output logic [2:0]                arprot_out,
    input  logic                      arvalid_in,
    output logic                      arvalid_out,
    input  logic                      arready,

    input  logic [ID_WIDTH-1:0]       rid,
    input  logic [DATA_WIDTH-1:0]     rdata,
    input  logic [1:0]                rresp,
    input  logic                      rlast,
    input  logic                      rvalid,
    input  logic                      rready_in,
    output logic                      rready_out
);

    import axi_types_pkg::*;

    axi_cmd_mbx_t uvm_to_bfm;
    axi_ev_mbx_t  bfm_to_uvm;

    longint unsigned cycle_count = 0;
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) cycle_count <= 0;
        else          cycle_count <= cycle_count + 1;
    end

    // Effective observed signals
    wire [ID_WIDTH-1:0]       eff_awid    = IS_ACTIVE ? awid_out    : awid_in;
    wire [ADDR_WIDTH-1:0]     eff_awaddr  = IS_ACTIVE ? awaddr_out  : awaddr_in;
    wire [7:0]                eff_awlen   = IS_ACTIVE ? awlen_out   : awlen_in;
    wire [2:0]                eff_awsize  = IS_ACTIVE ? awsize_out  : awsize_in;
    wire [1:0]                eff_awburst = IS_ACTIVE ? awburst_out : awburst_in;
    wire                      eff_awvalid = IS_ACTIVE ? awvalid_out : awvalid_in;

    wire [DATA_WIDTH-1:0]     eff_wdata   = IS_ACTIVE ? wdata_out   : wdata_in;
    wire [(DATA_WIDTH/8)-1:0] eff_wstrb   = IS_ACTIVE ? wstrb_out   : wstrb_in;
    wire                      eff_wlast   = IS_ACTIVE ? wlast_out   : wlast_in;
    wire                      eff_wvalid  = IS_ACTIVE ? wvalid_out  : wvalid_in;

    wire [ID_WIDTH-1:0]       eff_arid    = IS_ACTIVE ? arid_out    : arid_in;
    wire [ADDR_WIDTH-1:0]     eff_araddr  = IS_ACTIVE ? araddr_out  : araddr_in;
    wire [7:0]                eff_arlen   = IS_ACTIVE ? arlen_out   : arlen_in;
    wire [2:0]                eff_arsize  = IS_ACTIVE ? arsize_out  : arsize_in;
    wire [1:0]                eff_arburst = IS_ACTIVE ? arburst_out : arburst_in;
    wire                      eff_arvalid = IS_ACTIVE ? arvalid_out : arvalid_in;

    wire                      eff_bready  = IS_ACTIVE ? bready_out  : bready_in;
    wire                      eff_rready  = IS_ACTIVE ? rready_out  : rready_in;

    // Passive monitoring tasks for all five channels
    task monitor_aw();
        axi_bfm_event ev;
        forever begin
            @(posedge ACLK);
            if (ARESETn && eff_awvalid && awready) begin
                ev.channel_id    = AXI_CH_AW;
                ev.timestamp     = $time;
                ev.cycle_count   = cycle_count;
                ev.valid         = 1'b1;
                ev.ready         = 1'b1;
                ev.id            = eff_awid;
                ev.addr          = eff_awaddr;
                ev.burst_len     = eff_awlen;
                ev.transfer_size = eff_awsize;
                ev.burst_type    = axi_burst_e'(eff_awburst);
                bfm_to_uvm.put(ev);
            end
        end
    endtask

    task monitor_w();
        axi_bfm_event ev;
        forever begin
            @(posedge ACLK);
            if (ARESETn && eff_wvalid && wready) begin
                ev.channel_id  = AXI_CH_W;
                ev.timestamp   = $time;
                ev.cycle_count = cycle_count;
                ev.valid       = 1'b1;
                ev.ready       = 1'b1;
                ev.data        = eff_wdata;
                ev.wstrb       = eff_wstrb;
                ev.last        = eff_wlast;
                bfm_to_uvm.put(ev);
            end
        end
    endtask

    task monitor_b();
        axi_bfm_event ev;
        forever begin
            @(posedge ACLK);
            if (ARESETn && bvalid && eff_bready) begin
                ev.channel_id  = AXI_CH_B;
                ev.timestamp   = $time;
                ev.cycle_count = cycle_count;
                ev.valid       = 1'b1;
                ev.ready       = 1'b1;
                ev.id          = bid;
                ev.resp        = axi_resp_e'(bresp);
                bfm_to_uvm.put(ev);
            end
        end
    endtask

    task monitor_ar();
        axi_bfm_event ev;
        forever begin
            @(posedge ACLK);
            if (ARESETn && eff_arvalid && arready) begin
                ev.channel_id    = AXI_CH_AR;
                ev.timestamp     = $time;
                ev.cycle_count   = cycle_count;
                ev.valid         = 1'b1;
                ev.ready         = 1'b1;
                ev.id            = eff_arid;
                ev.addr          = eff_araddr;
                ev.burst_len     = eff_arlen;
                ev.transfer_size = eff_arsize;
                ev.burst_type    = axi_burst_e'(eff_arburst);
                bfm_to_uvm.put(ev);
            end
        end
    endtask

    task monitor_r();
        axi_bfm_event ev;
        forever begin
            @(posedge ACLK);
            if (ARESETn && rvalid && eff_rready) begin
                ev.channel_id  = AXI_CH_R;
                ev.timestamp   = $time;
                ev.cycle_count = cycle_count;
                ev.valid       = 1'b1;
                ev.ready       = 1'b1;
                ev.id          = rid;
                ev.data        = rdata;
                ev.resp        = axi_resp_e'(rresp);
                ev.last        = rlast;
                bfm_to_uvm.put(ev);
            end
        end
    endtask

    initial begin
        if (!IS_ACTIVE) begin
            // In Passive mode, outputs remain unasserted
            awvalid_out = 1'b0;
            wvalid_out  = 1'b0;
            arvalid_out = 1'b0;
            bready_out  = 1'b0;
            rready_out  = 1'b0;
        end
        fork
            monitor_aw();
            monitor_w();
            monitor_b();
            monitor_ar();
            monitor_r();
        join
    end

endinterface : axi_master_bfm

`endif // AXI_MASTER_BFM_SV
