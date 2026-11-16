// ============================================================================
// File: user_bfm.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Mailbox-synchronized Bus Functional Model for User-Side Interface.
//              Drives command requests and streaming write payloads; accepts
//              streaming read data and monitors status flags.
// ============================================================================

`ifndef USER_BFM_SV
`define USER_BFM_SV

import axi_types_pkg::*;

interface user_bfm #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    input logic clk,
    input logic rst_n,

    // Command Channel
    output logic [ADDR_WIDTH-1:0]     user_start_addr,
    output logic [31:0]               user_total_bytes,
    output logic                      user_rnw,
    output logic [1:0]                user_burst,
    output logic                      user_cmd_valid,
    input  logic                      user_cmd_ready,

    // TX Data Channel
    output logic [DATA_WIDTH-1:0]     user_tx_data,
    output logic [(DATA_WIDTH/8)-1:0] user_tx_wstrb,
    output logic                      user_tx_valid,
    input  logic                      user_tx_ready,

    // RX Data Channel
    input  logic [DATA_WIDTH-1:0]     user_rx_data,
    input  logic                      user_rx_valid,
    output logic                      user_rx_ready,

    // Status Signals
    input  logic                      write_complete,
    input  logic                      write_error,
    input  logic                      read_error
);

    mailbox #(user_bfm_command) uvm_to_bfm;
    mailbox #(user_bfm_event)   bfm_to_uvm;

    longint unsigned cycle_count = 0;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) cycle_count <= 0;
        else        cycle_count <= cycle_count + 1;
    end

    // Ready knob for RX
    int unsigned rx_ready_delay = 0;

    // Reset task
    task reset_signals();
        user_start_addr  <= '0;
        user_total_bytes <= '0;
        user_rnw         <= 1'b0;
        user_burst       <= 2'b01;
        user_cmd_valid   <= 1'b0;
        user_tx_data     <= '0;
        user_tx_wstrb    <= '0;
        user_tx_valid    <= 1'b0;
        user_rx_ready    <= 1'b1;
    endtask

    // Command and TX Data Driver process
    task driver_process();
        user_bfm_command cmd;
        user_bfm_event ev;
        forever begin
            uvm_to_bfm.get(cmd);

            // Command phase
            if (cmd.cmd_delay > 0) begin
                user_cmd_valid <= 1'b0;
                repeat (cmd.cmd_delay) @(posedge clk);
            end

            user_start_addr  <= cmd.start_addr;
            user_total_bytes <= cmd.total_bytes;
            user_rnw         <= cmd.rnw;
            user_burst       <= cmd.burst;
            user_cmd_valid   <= 1'b1;

            // Wait for handshake
            do begin
                @(posedge clk);
            end while (!(user_cmd_valid && user_cmd_ready) && rst_n);

            if (rst_n && user_cmd_valid && user_cmd_ready) begin
                ev.timestamp      = $time;
                ev.cycle_count    = cycle_count;
                ev.is_cmd         = 1'b1;
                ev.is_rx          = 1'b0;
                ev.addr           = cmd.start_addr;
                ev.total_bytes    = cmd.total_bytes;
                ev.rnw            = cmd.rnw;
                ev.burst          = cmd.burst;
                bfm_to_uvm.put(ev);
            end
            user_cmd_valid <= 1'b0;

            // If write operation, drive TX data stream
            if (!cmd.rnw) begin
                for (int i = 0; i < cmd.data_words.size(); i++) begin
                    int delay;
                    delay = (i < cmd.data_delay.size()) ? cmd.data_delay[i] : 0;
                    if (delay > 0) begin
                        user_tx_valid <= 1'b0;
                        repeat (delay) @(posedge clk);
                    end

                    user_tx_data  <= cmd.data_words[i];
                    user_tx_wstrb <= (i < cmd.wstrb.size()) ? cmd.wstrb[i] : 4'b1111;
                    user_tx_valid <= 1'b1;

                    do begin
                        @(posedge clk);
                    end while (!(user_tx_valid && user_tx_ready) && rst_n);

                    if (rst_n && user_tx_valid && user_tx_ready) begin
                        ev.timestamp   = $time;
                        ev.cycle_count = cycle_count;
                        ev.is_cmd      = 1'b0;
                        ev.is_rx       = 1'b0;
                        ev.data        = cmd.data_words[i];
                        ev.wstrb       = (i < cmd.wstrb.size()) ? cmd.wstrb[i] : 4'b1111;
                        bfm_to_uvm.put(ev);
                    end
                end
                user_tx_valid <= 1'b0;
            end
        end
    endtask

    // RX Data Monitor / Collector process
    task rx_process();
        user_bfm_event ev;
        forever begin
            @(posedge clk);
            if (!rst_n) begin
                user_rx_ready <= 1'b1;
                continue;
            end

            user_rx_ready <= 1'b1;
            if (user_rx_valid && user_rx_ready) begin
                ev.timestamp   = $time;
                ev.cycle_count = cycle_count;
                ev.is_cmd      = 1'b0;
                ev.is_rx       = 1'b1;
                ev.data        = user_rx_data;
                bfm_to_uvm.put(ev);
            end
        end
    endtask

    // Status Signal Monitor process
    task status_process();
        user_bfm_event ev;
        forever begin
            @(posedge clk);
            if (rst_n && (write_complete || write_error || read_error)) begin
                ev.timestamp      = $time;
                ev.cycle_count    = cycle_count;
                ev.is_cmd         = 1'b1;
                ev.write_complete = write_complete;
                ev.write_error    = write_error;
                ev.read_error     = read_error;
                bfm_to_uvm.put(ev);
            end
        end
    endtask

    initial begin
        reset_signals();
        wait(rst_n === 1'b1);
        fork
            driver_process();
            rx_process();
            status_process();
        join
    end

endinterface : user_bfm

`endif // USER_BFM_SV
