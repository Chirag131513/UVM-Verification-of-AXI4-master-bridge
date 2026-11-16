// ============================================================================
// File: user_agent.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: UVM Agent for User-Side Interface of AXI4 Master Bridge.
// ============================================================================

`ifndef USER_AGENT_SV
`define USER_AGENT_SV

class user_agent extends uvm_agent;
    `uvm_component_utils(user_agent)

    user_agent_config cfg;
    user_sequencer    sqr;
    user_driver       drv;
    user_monitor      mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(user_agent_config)::get(this, "", "cfg", cfg)) begin
            cfg = user_agent_config::type_id::create("cfg");
        end

        mon = user_monitor::type_id::create("mon", this);

        if (cfg.is_active == UVM_ACTIVE) begin
            sqr = user_sequencer::type_id::create("sqr", this);
            drv = user_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass : user_agent

`endif // USER_AGENT_SV
