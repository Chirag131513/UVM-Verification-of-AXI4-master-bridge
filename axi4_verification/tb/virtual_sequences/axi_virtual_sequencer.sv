// ============================================================================
// File: axi_virtual_sequencer.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Virtual Sequencer coordinating Master, Slave, and User sequencers.
// ============================================================================

`ifndef AXI_VIRTUAL_SEQUENCER_SV
`define AXI_VIRTUAL_SEQUENCER_SV

class axi_virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(axi_virtual_sequencer)

    // Sub-sequencer handles
    axi_master_sequencer mst_sqr;
    axi_slave_sequencer  slv_sqr;
    user_sequencer       usr_sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass : axi_virtual_sequencer

`endif // AXI_VIRTUAL_SEQUENCER_SV
