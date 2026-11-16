// ============================================================================
// File: user_monitor.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: User-side Interface Monitor observing command requests,
//              streaming write payload beats, and streaming read data beats.
// ============================================================================

`ifndef USER_MONITOR_SV
`define USER_MONITOR_SV

class user_monitor extends uvm_monitor;
    `uvm_component_utils(user_monitor)

    virtual user_interface.monitor_mp vif;
    user_agent_config cfg;

    uvm_analysis_port #(user_transaction) item_collected_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual user_interface.monitor_mp)::get(this, "", "vif", vif)) begin
            `uvm_fatal("USR_MON", "virtual user_interface.monitor_mp not found in config_db")
        end
        if (!uvm_config_db#(user_agent_config)::get(this, "", "cfg", cfg)) begin
            cfg = user_agent_config::type_id::create("cfg");
        end
    endfunction

    task run_phase(uvm_phase phase);
        wait(vif.rst_n === 1'b1);
        fork
            monitor_commands();
            monitor_status();
        join
    endtask

    // Monitor user command stream
    task monitor_commands();
        forever begin
            @(vif.cb_mon);
            if (vif.rst_n && vif.cb_mon.user_cmd_valid && vif.cb_mon.user_cmd_ready) begin
                user_transaction tx = user_transaction::type_id::create("usr_tx");
                tx.start_addr  = vif.cb_mon.user_start_addr;
                tx.total_bytes = vif.cb_mon.user_total_bytes;
                tx.rnw         = vif.cb_mon.user_rnw;
                tx.burst       = vif.cb_mon.user_burst;

                // If write, collect accompanying TX data beats
                if (!tx.rnw) begin
                    int num_words;
                    num_words = (tx.total_bytes + tx.start_addr[1:0] + 3) / 4;
                    tx.tx_data  = new[num_words];
                    tx.tx_wstrb = new[num_words];

                    for (int w = 0; w < num_words; w++) begin
                        do begin
                            @(vif.cb_mon);
                        end while (!(vif.cb_mon.user_tx_valid && vif.cb_mon.user_tx_ready) && vif.rst_n);

                        if (vif.rst_n) begin
                            tx.tx_data[w]  = vif.cb_mon.user_tx_data;
                            tx.tx_wstrb[w] = vif.cb_mon.user_tx_wstrb;
                        end
                    end
                end

                `uvm_info("USR_MON", $sformatf("Observed User Transaction: %s", tx.convert2string()), UVM_HIGH)
                item_collected_port.write(tx);
            end
        end
    endtask

    // Monitor status flags
    task monitor_status();
        forever begin
            @(vif.cb_mon);
            if (vif.rst_n && (vif.cb_mon.write_complete || vif.cb_mon.write_error || vif.cb_mon.read_error)) begin
                `uvm_info("USR_MON", $sformatf("Status Flag Pulse: WComplete=%0b WErr=%0b RErr=%0b",
                          vif.cb_mon.write_complete, vif.cb_mon.write_error, vif.cb_mon.read_error), UVM_HIGH)
            end
        end
    endtask

endclass : user_monitor

`endif // USER_MONITOR_SV
