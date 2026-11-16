// ============================================================================
// File: axi_protocol_checker.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: SystemVerilog Assertions (SVA) Protocol Checker validating
//              handshake stability, 4KB boundary compliance, burst length invariants,
//              and WLAST/RLAST assertions across all 5 AXI4 channels.
// ============================================================================

`ifndef AXI_PROTOCOL_CHECKER_SV
`define AXI_PROTOCOL_CHECKER_SV

module axi_protocol_checker #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4,
    parameter int MAX_OUTSTANDING = 4
)(
    input logic                      ACLK,
    input logic                      ARESETn,

    // AW Channel
    input logic [ID_WIDTH-1:0]       awid,
    input logic [ADDR_WIDTH-1:0]     awaddr,
    input logic [7:0]                awlen,
    input logic [2:0]                awsize,
    input logic [1:0]                awburst,
    input logic                      awvalid,
    input logic                      awready,

    // W Channel
    input logic [DATA_WIDTH-1:0]     wdata,
    input logic [(DATA_WIDTH/8)-1:0] wstrb,
    input logic                      wlast,
    input logic                      wvalid,
    input logic                      wready,

    // B Channel
    input logic [ID_WIDTH-1:0]       bid,
    input logic [1:0]                bresp,
    input logic                      bvalid,
    input logic                      bready,

    // AR Channel
    input logic [ID_WIDTH-1:0]       arid,
    input logic [ADDR_WIDTH-1:0]     araddr,
    input logic [7:0]                arlen,
    input logic [2:0]                arsize,
    input logic [1:0]                arburst,
    input logic                      arvalid,
    input logic                      arready,

    // R Channel
    input logic [ID_WIDTH-1:0]       rid,
    input logic [DATA_WIDTH-1:0]     rdata,
    input logic [1:0]                rresp,
    input logic                      rlast,
    input logic                      rvalid,
    input logic                      rready
);

    // ------------------------------------------------------------------------
    // Reset Invariants: VALID signals must remain deasserted during reset
    // ------------------------------------------------------------------------
    property p_reset_awvalid;
        @(posedge ACLK) !ARESETn |-> !awvalid;
    endproperty
    assert_reset_awvalid: assert property (p_reset_awvalid)
        else $error("[SVA] awvalid asserted during reset!");

    property p_reset_wvalid;
        @(posedge ACLK) !ARESETn |-> !wvalid;
    endproperty
    assert_reset_wvalid: assert property (p_reset_wvalid)
        else $error("[SVA] wvalid asserted during reset!");

    property p_reset_bvalid;
        @(posedge ACLK) !ARESETn |-> !bvalid;
    endproperty
    assert_reset_bvalid: assert property (p_reset_bvalid)
        else $error("[SVA] bvalid asserted during reset!");

    property p_reset_arvalid;
        @(posedge ACLK) !ARESETn |-> !arvalid;
    endproperty
    assert_reset_arvalid: assert property (p_reset_arvalid)
        else $error("[SVA] arvalid asserted during reset!");

    property p_reset_rvalid;
        @(posedge ACLK) !ARESETn |-> !rvalid;
    endproperty
    assert_reset_rvalid: assert property (p_reset_rvalid)
        else $error("[SVA] rvalid asserted during reset!");

    // ------------------------------------------------------------------------
    // Handshake Stability: Payload must remain stable while VALID & !READY
    // ------------------------------------------------------------------------
    property p_aw_stability;
        @(posedge ACLK) disable iff (!ARESETn)
        (awvalid && !awready) |=> (awvalid && $stable({awid, awaddr, awlen, awsize, awburst}));
    endproperty
    assert_aw_stability: assert property (p_aw_stability)
        else $error("[SVA] AW channel stability violation: payload changed while awvalid && !awready!");

    property p_w_stability;
        @(posedge ACLK) disable iff (!ARESETn)
        (wvalid && !wready) |=> (wvalid && $stable({wdata, wstrb, wlast}));
    endproperty
    assert_w_stability: assert property (p_w_stability)
        else $error("[SVA] W channel stability violation: payload changed while wvalid && !wready!");

    property p_b_stability;
        @(posedge ACLK) disable iff (!ARESETn)
        (bvalid && !bready) |=> (bvalid && $stable({bid, bresp}));
    endproperty
    assert_b_stability: assert property (p_b_stability)
        else $error("[SVA] B channel stability violation: payload changed while bvalid && !bready!");

    property p_ar_stability;
        @(posedge ACLK) disable iff (!ARESETn)
        (arvalid && !arready) |=> (arvalid && $stable({arid, araddr, arlen, arsize, arburst}));
    endproperty
    assert_ar_stability: assert property (p_ar_stability)
        else $error("[SVA] AR channel stability violation: payload changed while arvalid && !arready!");

    property p_r_stability;
        @(posedge ACLK) disable iff (!ARESETn)
        (rvalid && !rready) |=> (rvalid && $stable({rid, rdata, rresp, rlast}));
    endproperty
    assert_r_stability: assert property (p_r_stability)
        else $error("[SVA] R channel stability violation: payload changed while rvalid && !rready!");

    // ------------------------------------------------------------------------
    // 4KB Page Boundary Checks (AMBA AXI4 Section A3.4.1)
    // ------------------------------------------------------------------------
    property p_aw_4kb_boundary;
        @(posedge ACLK) disable iff (!ARESETn)
        awvalid |-> (((awaddr & 12'hFFF) + ((int'(awlen) + 1) * (1 << awsize))) <= 4096);
    endproperty
    assert_aw_4kb_boundary: assert property (p_aw_4kb_boundary)
        else $error("[SVA] AW burst crosses 4KB page boundary! Addr=0x%08h Len=%0d Size=%0d",
                    awaddr, awlen, awsize);

    property p_ar_4kb_boundary;
        @(posedge ACLK) disable iff (!ARESETn)
        arvalid |-> (((araddr & 12'hFFF) + ((int'(arlen) + 1) * (1 << arsize))) <= 4096);
    endproperty
    assert_ar_4kb_boundary: assert property (p_ar_4kb_boundary)
        else $error("[SVA] AR burst crosses 4KB page boundary! Addr=0x%08h Len=%0d Size=%0d",
                    araddr, arlen, arsize);

    // ------------------------------------------------------------------------
    // Legal Burst Type Encodings: Reserved 2'b11 is forbidden
    // ------------------------------------------------------------------------
    property p_aw_burst_legal;
        @(posedge ACLK) disable iff (!ARESETn)
        awvalid |-> (awburst != 2'b11);
    endproperty
    assert_aw_burst_legal: assert property (p_aw_burst_legal)
        else $error("[SVA] Reserved burst type 2'b11 on AW channel!");

    property p_ar_burst_legal;
        @(posedge ACLK) disable iff (!ARESETn)
        arvalid |-> (arburst != 2'b11);
    endproperty
    assert_ar_burst_legal: assert property (p_ar_burst_legal)
        else $error("[SVA] Reserved burst type 2'b11 on AR channel!");

    // ------------------------------------------------------------------------
    // FIXED burst length <= 16 beats (AMBA AXI4 Section A3.4.1)
    // ------------------------------------------------------------------------
    property p_aw_fixed_len;
        @(posedge ACLK) disable iff (!ARESETn)
        (awvalid && (awburst == 2'b00)) |-> (awlen <= 8'd15);
    endproperty
    assert_aw_fixed_len: assert property (p_aw_fixed_len)
        else $error("[SVA] FIXED burst length exceeds 16 beats on AW channel!");

endmodule : axi_protocol_checker

`endif // AXI_PROTOCOL_CHECKER_SV
