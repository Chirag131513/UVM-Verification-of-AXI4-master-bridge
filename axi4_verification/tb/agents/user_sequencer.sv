// ============================================================================
// File: user_sequencer.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: UVM Sequencer for user-side command & payload transactions.
// ============================================================================

`ifndef USER_SEQUENCER_SV
`define USER_SEQUENCER_SV

class user_sequencer extends uvm_sequencer #(user_transaction);
    `uvm_component_utils(user_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass : user_sequencer

`endif // USER_SEQUENCER_SV
