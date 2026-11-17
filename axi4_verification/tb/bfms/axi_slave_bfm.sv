// ============================================================================
// File: axi_slave_bfm.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Mailbox-synchronized Bus Functional Model (BFM) for AXI4 Slave.
//              Handles independent AW, W, B, AR, and R channel handshakes,
//              controlled by uvm_to_bfm and reporting via bfm_to_uvm.
// ============================================================================

`ifndef AXI_SLAVE_BFM_SV
`define AXI_SLAVE_BFM_SV

interface axi_slave_bfm #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4
)(
    input logic ACLK,
    input logic ARESETn,
    
    // Physical AXI Interface ports
    input  logic [ID_WIDTH-1:0]       awid,
    input  logic [ADDR_WIDTH-1:0]     awaddr,
    input  logic [7:0]                awlen,
    input  logic [2:0]                awsize,
    input  logic [1:0]                awburst,
    input  logic [3:0]                awcache,
    input  logic [2:0]                awprot,
    input  logic                      awvalid,
    output logic                      awready,

    input  logic [DATA_WIDTH-1:0]     wdata,
    input  logic [(DATA_WIDTH/8)-1:0] wstrb,
    input  logic                      wlast,
    input  logic                      wvalid,
    output logic                      wready,

    output logic [ID_WIDTH-1:0]       bid,
    output logic [1:0]                bresp,
    output logic                      bvalid,
    input  logic                      bready,

    input  logic [ID_WIDTH-1:0]       arid,
    input  logic [ADDR_WIDTH-1:0]     araddr,
    input  logic [7:0]                arlen,
    input  logic [2:0]                arsize,
    input  logic [1:0]                arburst,
    input  logic [3:0]                arcache,
    input  logic [2:0]                arprot,
    input  logic                      arvalid,
    output logic                      arready,

    output logic [ID_WIDTH-1:0]       rid,
    output logic [DATA_WIDTH-1:0]     rdata,
    output logic [1:0]                rresp,
    output logic                      rlast,
    output logic                      rvalid,
    input  logic                      rready
);

    import axi_types_pkg::*;

    // ------------------------------------------------------------------------
    // Mailboxes for Synchronization with UVM Driver & Monitor
    // ------------------------------------------------------------------------
    axi_cmd_mbx_t uvm_to_bfm;
    axi_ev_mbx_t  bfm_to_uvm;

    // Cycle counter
    longint unsigned cycle_count;
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) cycle_count <= 0;
        else          cycle_count <= cycle_count + 1;
    end

    // Internal queues for commands targeted to specific channels
    axi_bfm_command b_cmd_q[$];
    axi_bfm_command r_cmd_q[$];

    // Ready configuration controls
    int unsigned aw_ready_delay = 0;
    int unsigned w_ready_delay  = 0;
    int unsigned ar_ready_delay = 0;

    // ------------------------------------------------------------------------
    // Reset handling
    // ------------------------------------------------------------------------
    task reset_signals();
        awready <= 1'b0;
        wready  <= 1'b0;
        bvalid  <= 1'b0;
        bid     <= '0;
        bresp   <= '0;
        arready <= 1'b0;
        rvalid  <= 1'b0;
        rid     <= '0;
        rdata   <= '0;
        rresp   <= '0;
        rlast   <= 1'b0;
        b_cmd_q.delete();
        r_cmd_q.delete();
    endtask

    // ------------------------------------------------------------------------
    // Command Dispatcher from UVM Driver
    // ------------------------------------------------------------------------
    task command_dispatcher();
        axi_bfm_command cmd;
        forever begin
            uvm_to_bfm.get(cmd);
            case (cmd.channel_id)
                AXI_CH_AW: aw_ready_delay = cmd.delay_cycles;
                AXI_CH_W:  w_ready_delay  = cmd.delay_cycles;
                AXI_CH_AR: ar_ready_delay = cmd.delay_cycles;
                AXI_CH_B:  b_cmd_q.push_back(cmd);
                AXI_CH_R:  r_cmd_q.push_back(cmd);
                default: ;
            endcase
        end
    endtask

    // ------------------------------------------------------------------------
    // 1. AW Channel Process
    // ------------------------------------------------------------------------
    task aw_channel_process();
        axi_bfm_event ev;
        forever begin
            @(posedge ACLK);
            if (!ARESETn) begin
                awready <= 1'b0;
                continue;
            end

            // Assert ready with configured delay
            if (aw_ready_delay > 0) begin
                awready <= 1'b0;
                repeat (aw_ready_delay) @(posedge ACLK);
            end
            awready <= 1'b1;

            // Wait for handshake
            do begin
                @(posedge ACLK);
            end while (!(awvalid && awready) && ARESETn);

            if (ARESETn && awvalid && awready) begin
                ev.channel_id    = AXI_CH_AW;
                ev.timestamp     = $time;
                ev.cycle_count   = cycle_count;
                ev.valid         = 1'b1;
                ev.ready         = 1'b1;
                ev.id            = awid;
                ev.addr          = awaddr;
                ev.burst_len     = awlen;
                ev.transfer_size = awsize;
                ev.burst_type    = axi_burst_e'(awburst);
                ev.cache         = awcache;
                ev.prot          = awprot;
                bfm_to_uvm.put(ev);
            end
        end
    endtask

    // ------------------------------------------------------------------------
    // 2. W Channel Process
    // ------------------------------------------------------------------------
    task w_channel_process();
        axi_bfm_event ev;
        forever begin
            @(posedge ACLK);
            if (!ARESETn) begin
                wready <= 1'b0;
                continue;
            end

            if (w_ready_delay > 0) begin
                wready <= 1'b0;
                repeat (w_ready_delay) @(posedge ACLK);
            end
            wready <= 1'b1;

            do begin
                @(posedge ACLK);
            end while (!(wvalid && wready) && ARESETn);

            if (ARESETn && wvalid && wready) begin
                ev.channel_id  = AXI_CH_W;
                ev.timestamp   = $time;
                ev.cycle_count = cycle_count;
                ev.valid       = 1'b1;
                ev.ready       = 1'b1;
                ev.data        = wdata;
                ev.wstrb       = wstrb;
                ev.last        = wlast;
                bfm_to_uvm.put(ev);
            end
        end
    endtask

    // ------------------------------------------------------------------------
    // 3. B Channel Process
    // ------------------------------------------------------------------------
    task b_channel_process();
        axi_bfm_command cmd;
        axi_bfm_event ev;
        forever begin
            @(posedge ACLK);
            if (!ARESETn) begin
                bvalid <= 1'b0;
                continue;
            end

            if (b_cmd_q.size() > 0) begin
                cmd = b_cmd_q.pop_front();
                
                // Response delay
                if (cmd.delay_cycles > 0) begin
                    bvalid <= 1'b0;
                    repeat (cmd.delay_cycles) @(posedge ACLK);
                end

                bvalid <= 1'b1;
                bid    <= cmd.id;
                bresp  <= cmd.resp_code;

                // Hold stable until BREADY handshake (AXI stability invariant)
                do begin
                    @(posedge ACLK);
                end while (!(bvalid && bready) && ARESETn);

                if (ARESETn && bvalid && bready) begin
                    ev.channel_id  = AXI_CH_B;
                    ev.timestamp   = $time;
                    ev.cycle_count = cycle_count;
                    ev.valid       = 1'b1;
                    ev.ready       = 1'b1;
                    ev.id          = bid;
                    ev.resp        = axi_resp_e'(bresp);
                    bfm_to_uvm.put(ev);
                end
                bvalid <= 1'b0;
            end else begin
                bvalid <= 1'b0;
            end
        end
    endtask

    // ------------------------------------------------------------------------
    // 4. AR Channel Process
    // ------------------------------------------------------------------------
    task ar_channel_process();
        axi_bfm_event ev;
        forever begin
            @(posedge ACLK);
            if (!ARESETn) begin
                arready <= 1'b0;
                continue;
            end

            if (ar_ready_delay > 0) begin
                arready <= 1'b0;
                repeat (ar_ready_delay) @(posedge ACLK);
            end
            arready <= 1'b1;

            do begin
                @(posedge ACLK);
            end while (!(arvalid && arready) && ARESETn);

            if (ARESETn && arvalid && arready) begin
                ev.channel_id    = AXI_CH_AR;
                ev.timestamp     = $time;
                ev.cycle_count   = cycle_count;
                ev.valid         = 1'b1;
                ev.ready         = 1'b1;
                ev.id            = arid;
                ev.addr          = araddr;
                ev.burst_len     = arlen;
                ev.transfer_size = arsize;
                ev.burst_type    = axi_burst_e'(arburst);
                ev.cache         = arcache;
                ev.prot          = arprot;
                bfm_to_uvm.put(ev);
            end
        end
    endtask

    // ------------------------------------------------------------------------
    // 5. R Channel Process
    // ------------------------------------------------------------------------
    task r_channel_process();
        axi_bfm_command cmd;
        axi_bfm_event ev;
        forever begin
            @(posedge ACLK);
            if (!ARESETn) begin
                rvalid <= 1'b0;
                continue;
            end

            if (r_cmd_q.size() > 0) begin
                cmd = r_cmd_q.pop_front();

                for (int beat = 0; beat <= int'(cmd.burst_len); beat++) begin
                    if (cmd.delay_cycles > 0) begin
                        rvalid <= 1'b0;
                        repeat (cmd.delay_cycles) @(posedge ACLK);
                    end

                    rvalid <= 1'b1;
                    rid    <= cmd.id;
                    rdata  <= (beat < cmd.data.size()) ? cmd.data[beat] : '0;
                    rresp  <= cmd.resp_code;
                    rlast  <= (beat == int'(cmd.burst_len));

                    // Hold stable until RREADY handshake
                    do begin
                        @(posedge ACLK);
                    end while (!(rvalid && rready) && ARESETn);

                    if (ARESETn && rvalid && rready) begin
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
                rvalid <= 1'b0;
                rlast  <= 1'b0;
            end else begin
                rvalid <= 1'b0;
                rlast  <= 1'b0;
            end
        end
    endtask

    // ------------------------------------------------------------------------
    // Top BFM Runner
    // ------------------------------------------------------------------------
    initial begin
        reset_signals();
        wait(ARESETn === 1'b1);
        fork
            command_dispatcher();
            aw_channel_process();
            w_channel_process();
            b_channel_process();
            ar_channel_process();
            r_channel_process();
        join
    end

endinterface : axi_slave_bfm

`endif // AXI_SLAVE_BFM_SV
