// ============================================================================
// File: user_driver.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: User-side Driver converting user_transaction items to user_bfm commands.
// ============================================================================

`ifndef USER_DRIVER_SV
`define USER_DRIVER_SV

class user_driver extends uvm_driver #(user_transaction);
    `uvm_component_utils(user_driver)

    user_agent_config cfg;
    user_cmd_mbx_t    uvm_to_bfm;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(user_agent_config)::get(this, "", "cfg", cfg)) begin
            cfg = user_agent_config::type_id::create("cfg");
        end
        if (!uvm_config_db#(user_cmd_mbx_t)::get(this, "", "uvm_to_bfm", uvm_to_bfm)) begin
            `uvm_fatal("USR_DRV", "uvm_to_bfm mailbox not found in config_db")
        end
    endfunction

    task run_phase(uvm_phase phase);
        user_bfm_command cmd;
        forever begin
            seq_item_port.get_next_item(req);

            cmd.start_addr  = req.start_addr;
            cmd.total_bytes = req.total_bytes;
            cmd.rnw         = req.rnw;
            cmd.burst       = req.burst;
            cmd.cmd_delay   = req.cmd_delay;
            cmd.data_words  = req.tx_data;
            cmd.wstrb       = req.tx_wstrb;
            cmd.data_delay  = req.tx_delay;

            uvm_to_bfm.put(cmd);
            seq_item_port.item_done();
        end
    endtask

endclass : user_driver

`endif // USER_DRIVER_SV
