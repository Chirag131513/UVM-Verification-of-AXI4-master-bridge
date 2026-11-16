// ============================================================================
// File: axi_master_agent.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: UVM Agent for AXI4 Master. Supports Active/Passive mode.
// ============================================================================

`ifndef AXI_MASTER_AGENT_SV
`define AXI_MASTER_AGENT_SV

class axi_master_agent extends uvm_agent;
    `uvm_component_utils(axi_master_agent)

    axi_master_config    cfg;
    axi_master_sequencer sqr;
    axi_master_driver    drv;
    axi_master_monitor   mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(axi_master_config)::get(this, "", "cfg", cfg)) begin
            cfg = axi_master_config::type_id::create("cfg");
        end

        mon = axi_master_monitor::type_id::create("mon", this);

        if (cfg.is_active == UVM_ACTIVE) begin
            sqr = axi_master_sequencer::type_id::create("sqr", this);
            drv = axi_master_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass : axi_master_agent

`endif // AXI_MASTER_AGENT_SV
