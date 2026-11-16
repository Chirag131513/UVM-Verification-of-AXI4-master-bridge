// ============================================================================
// File: tb_top.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Top-level Testbench Module instantiating Master Bridge DUT,
//              interfaces, mailbox-synchronized BFMs, SVA protocol checker,
//              and initiating the UVM phase execution.
// ============================================================================

`timescale 1ns/1ps

module tb_top;

    import uvm_pkg::*;
    import axi_types_pkg::*;
    import axi_vip_pkg::*;

    // Parameters
    parameter int ADDR_WIDTH      = 32;
    parameter int DATA_WIDTH      = 32;
    parameter int ID_WIDTH        = 4;
    parameter int FIFO_DEPTH      = 16;
    parameter int MAX_OUTSTANDING = 4;

    // Clock and Reset Generation
    logic ACLK;
    logic ARESETn;

    initial begin
        ACLK = 1'b0;
        forever #5ns ACLK = ~ACLK; // 100 MHz clock
    end

    initial begin
        ARESETn = 1'b0;
        #30ns;
        @(negedge ACLK);
        ARESETn = 1'b1;
    end

    // Waveform Dumping for debug (GTKWave / SimVision / Verdi)
    initial begin
        if ($test$plusargs("DUMP_VCD") || $test$plusargs("WAVE")) begin
            $dumpfile("axi4_tb.vcd");
            $dumpvars(0, tb_top);
        end
    end

    // ------------------------------------------------------------------------
    // Physical Interfaces
    // ------------------------------------------------------------------------
    axi_interface #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    ) axi_if (
        .ACLK    (ACLK),
        .ARESETn (ARESETn)
    );

    user_interface #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) user_if (
        .clk   (ACLK),
        .rst_n (ARESETn)
    );

    // ------------------------------------------------------------------------
    // Mailbox-Synchronized Bus Functional Models (BFMs)
    // ------------------------------------------------------------------------
    axi_slave_bfm #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    ) slave_bfm (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),
        .awid    (axi_if.awid),
        .awaddr  (axi_if.awaddr),
        .awlen   (axi_if.awlen),
        .awsize  (axi_if.awsize),
        .awburst (axi_if.awburst),
        .awcache (axi_if.awcache),
        .awprot  (axi_if.awprot),
        .awvalid (axi_if.awvalid),
        .awready (axi_if.awready),
        .wdata   (axi_if.wdata),
        .wstrb   (axi_if.wstrb),
        .wlast   (axi_if.wlast),
        .wvalid  (axi_if.wvalid),
        .wready  (axi_if.wready),
        .bid     (axi_if.bid),
        .bresp   (axi_if.bresp),
        .bvalid  (axi_if.bvalid),
        .bready  (axi_if.bready),
        .arid    (axi_if.arid),
        .araddr  (axi_if.araddr),
        .arlen   (axi_if.arlen),
        .arsize  (axi_if.arsize),
        .arburst (axi_if.arburst),
        .arcache (axi_if.arcache),
        .arprot  (axi_if.arprot),
        .arvalid (axi_if.arvalid),
        .arready (axi_if.arready),
        .rid     (axi_if.rid),
        .rdata   (axi_if.rdata),
        .rresp   (axi_if.rresp),
        .rlast   (axi_if.rlast),
        .rvalid  (axi_if.rvalid),
        .rready  (axi_if.rready)
    );

    user_bfm #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) u_bfm (
        .clk              (ACLK),
        .rst_n            (ARESETn),
        .user_start_addr  (user_if.user_start_addr),
        .user_total_bytes (user_if.user_total_bytes),
        .user_rnw         (user_if.user_rnw),
        .user_burst       (user_if.user_burst),
        .user_cmd_valid   (user_if.user_cmd_valid),
        .user_cmd_ready   (user_if.user_cmd_ready),
        .user_tx_data     (user_if.user_tx_data),
        .user_tx_wstrb    (user_if.user_tx_wstrb),
        .user_tx_valid    (user_if.user_tx_valid),
        .user_tx_ready    (user_if.user_tx_ready),
        .user_rx_data     (user_if.user_rx_data),
        .user_rx_valid    (user_if.user_rx_valid),
        .user_rx_ready    (user_if.user_rx_ready),
        .write_complete   (user_if.write_complete),
        .write_error      (user_if.write_error),
        .read_error       (user_if.read_error)
    );

    // ------------------------------------------------------------------------
    // Design Under Verification (DUV)
    // ------------------------------------------------------------------------
    master_top #(
        .ADDR_WIDTH      (ADDR_WIDTH),
        .DATA_WIDTH      (DATA_WIDTH),
        .ID_WIDTH        (ID_WIDTH),
        .ID_VALUE        (4'b0000),
        .FIFO_DEPTH      (FIFO_DEPTH),
        .MAX_OUTSTANDING (MAX_OUTSTANDING)
    ) dut (
        .clk              (ACLK),
        .rst_n            (ARESETn),

        // User Command Interface
        .user_start_addr  (user_if.user_start_addr),
        .user_total_bytes (user_if.user_total_bytes),
        .user_rnw         (user_if.user_rnw),
        .user_burst       (user_if.user_burst),
        .user_cmd_valid   (user_if.user_cmd_valid),
        .user_cmd_ready   (user_if.user_cmd_ready),

        // User TX Data Stream
        .user_tx_data     (user_if.user_tx_data),
        .user_tx_valid    (user_if.user_tx_valid),
        .user_tx_wstrb    (user_if.user_tx_wstrb),
        .user_tx_ready    (user_if.user_tx_ready),

        // User RX Data Stream
        .user_rx_data     (user_if.user_rx_data),
        .user_rx_valid    (user_if.user_rx_valid),
        .user_rx_ready    (user_if.user_rx_ready),

        // Status Flags
        .write_complete   (user_if.write_complete),
        .write_error      (user_if.write_error),
        .read_error       (user_if.read_error),

        // AXI Write Address Channel (AW)
        .m_axi_awid       (axi_if.awid),
        .m_axi_awaddr     (axi_if.awaddr),
        .m_axi_awlen      (axi_if.awlen),
        .m_axi_awsize     (axi_if.awsize),
        .m_axi_awburst    (axi_if.awburst),
        .m_axi_awcache    (axi_if.awcache),
        .m_axi_awprot     (axi_if.awprot),
        .m_axi_awvalid    (axi_if.awvalid),
        .m_axi_awready    (axi_if.awready),

        // AXI Write Data Channel (W)
        .m_axi_wdata      (axi_if.wdata),
        .m_axi_wstrb      (axi_if.wstrb),
        .m_axi_wlast      (axi_if.wlast),
        .m_axi_wvalid     (axi_if.wvalid),
        .m_axi_wready     (axi_if.wready),

        // AXI Write Response Channel (B)
        .m_axi_bid        (axi_if.bid),
        .m_axi_bresp      (axi_if.bresp),
        .m_axi_bvalid     (axi_if.bvalid),
        .m_axi_bready     (axi_if.bready),

        // AXI Read Address Channel (AR)
        .m_axi_arid       (axi_if.arid),
        .m_axi_araddr     (axi_if.araddr),
        .m_axi_arlen      (axi_if.arlen),
        .m_axi_arsize     (axi_if.arsize),
        .m_axi_arburst    (axi_if.arburst),
        .m_axi_arcache    (axi_if.arcache),
        .m_axi_arprot     (axi_if.arprot),
        .m_axi_arvalid    (axi_if.arvalid),
        .m_axi_arready    (axi_if.arready),

        // AXI Read Data Channel (R)
        .m_axi_rid        (axi_if.rid),
        .m_axi_rdata      (axi_if.rdata),
        .m_axi_rresp      (axi_if.rresp),
        .m_axi_rlast      (axi_if.rlast),
        .m_axi_rvalid     (axi_if.rvalid),
        .m_axi_rready     (axi_if.rready)
    );

    // ------------------------------------------------------------------------
    // SVA Protocol Checker Instance
    // ------------------------------------------------------------------------
    axi_protocol_checker #(
        .ADDR_WIDTH      (ADDR_WIDTH),
        .DATA_WIDTH      (DATA_WIDTH),
        .ID_WIDTH        (ID_WIDTH),
        .MAX_OUTSTANDING (MAX_OUTSTANDING)
    ) sva_checker (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),
        .awid    (axi_if.awid),
        .awaddr  (axi_if.awaddr),
        .awlen   (axi_if.awlen),
        .awsize  (axi_if.awsize),
        .awburst (axi_if.awburst),
        .awvalid (axi_if.awvalid),
        .awready (axi_if.awready),
        .wdata   (axi_if.wdata),
        .wstrb   (axi_if.wstrb),
        .wlast   (axi_if.wlast),
        .wvalid  (axi_if.wvalid),
        .wready  (axi_if.wready),
        .bid     (axi_if.bid),
        .bresp   (axi_if.bresp),
        .bvalid  (axi_if.bvalid),
        .bready  (axi_if.bready),
        .arid    (axi_if.arid),
        .araddr  (axi_if.araddr),
        .arlen   (axi_if.arlen),
        .arsize  (axi_if.arsize),
        .arburst (axi_if.arburst),
        .arvalid (axi_if.arvalid),
        .arready (axi_if.arready),
        .rid     (axi_if.rid),
        .rdata   (axi_if.rdata),
        .rresp   (axi_if.rresp),
        .rlast   (axi_if.rlast),
        .rvalid  (axi_if.rvalid),
        .rready  (axi_if.rready)
    );

    // ------------------------------------------------------------------------
    // Mailbox-Synchronized BFM Communication Handles
    // ------------------------------------------------------------------------
    axi_cmd_mbx_t  slv_u2b;
    axi_ev_mbx_t   slv_b2u;
    user_cmd_mbx_t usr_u2b;
    user_ev_mbx_t  usr_b2u;

    // ------------------------------------------------------------------------
    // Configuration & UVM Test Kickoff
    // ------------------------------------------------------------------------
    initial begin
        // Instantiate and wire mailboxes
        slv_u2b = new();
        slv_b2u = new();
        usr_u2b = new();
        usr_b2u = new();

        slave_bfm.uvm_to_bfm = slv_u2b;
        slave_bfm.bfm_to_uvm = slv_b2u;

        u_bfm.uvm_to_bfm = usr_u2b;
        u_bfm.bfm_to_uvm = usr_b2u;

        // Populate UVM Config DB
        uvm_config_db#(virtual axi_interface.monitor_mp)::set(null, "*", "vif", axi_if.monitor_mp);
        uvm_config_db#(virtual user_interface.monitor_mp)::set(null, "*", "vif", user_if.monitor_mp);

        uvm_config_db#(axi_cmd_mbx_t)::set(null, "*slave_agent*", "uvm_to_bfm", slv_u2b);
        uvm_config_db#(axi_ev_mbx_t)::set(null, "*slave_agent*", "bfm_to_uvm", slv_b2u);

        uvm_config_db#(user_cmd_mbx_t)::set(null, "*user_agent*", "uvm_to_bfm", usr_u2b);
        uvm_config_db#(user_ev_mbx_t)::set(null, "*user_agent*", "bfm_to_uvm", usr_b2u);

        // Run default test (can be overridden via +UVM_TESTNAME)
        run_test("axi_directed_test");
    end

endmodule : tb_top
