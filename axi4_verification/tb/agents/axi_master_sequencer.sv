// ============================================================================
// File: axi_master_sequencer.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: UVM Sequencer for AXI4 Master transactions.
// ============================================================================

`ifndef AXI_MASTER_SEQUENCER_SV
`define AXI_MASTER_SEQUENCER_SV

class axi_master_sequencer extends uvm_sequencer #(axi_transaction);
    `uvm_component_utils(axi_master_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass : axi_master_sequencer

`endif // AXI_MASTER_SEQUENCER_SV
