// ============================================================================
// File: axi_slave_agent.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: UVM Agent for AXI4 Slave. Embeds reactive driver, monitor,
//              and sequencer.
// ============================================================================

`ifndef AXI_SLAVE_AGENT_SV
`define AXI_SLAVE_AGENT_SV

class axi_slave_agent extends uvm_agent;
    `uvm_component_utils(axi_slave_agent)

    axi_slave_config    cfg;
    axi_slave_sequencer sqr;
    axi_slave_driver    drv;
    axi_slave_monitor   mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(axi_slave_config)::get(this, "", "cfg", cfg)) begin
            cfg = axi_slave_config::type_id::create("cfg");
        end

        mon = axi_slave_monitor::type_id::create("mon", this);

        if (cfg.is_active == UVM_ACTIVE) begin
            sqr = axi_slave_sequencer::type_id::create("sqr", this);
            drv = axi_slave_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass : axi_slave_agent

`endif // AXI_SLAVE_AGENT_SV
