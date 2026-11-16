// ============================================================================
// File: axi_scoreboard.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Top-Level Scoreboard integrating the AXI Protocol Scoreboard
//              and the Functional Memory Scoreboard.
// ============================================================================

`ifndef AXI_SCOREBOARD_SV
`define AXI_SCOREBOARD_SV

class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)

    axi_protocol_scoreboard protocol_sbd;
    axi_memory_scoreboard   memory_sbd;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        protocol_sbd = axi_protocol_scoreboard::type_id::create("protocol_sbd", this);
        memory_sbd   = axi_memory_scoreboard::type_id::create("memory_sbd", this);
    endfunction

endclass : axi_scoreboard

`endif // AXI_SCOREBOARD_SV
