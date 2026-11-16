// ============================================================================
// File: axi_slave_sequencer.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: UVM Sequencer for reactive AXI4 Slave response items.
// ============================================================================

`ifndef AXI_SLAVE_SEQUENCER_SV
`define AXI_SLAVE_SEQUENCER_SV

class axi_slave_sequencer extends uvm_sequencer #(axi_transaction);
    `uvm_component_utils(axi_slave_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass : axi_slave_sequencer

`endif // AXI_SLAVE_SEQUENCER_SV
