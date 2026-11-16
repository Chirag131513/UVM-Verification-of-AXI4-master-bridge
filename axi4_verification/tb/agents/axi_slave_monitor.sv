// ============================================================================
// File: axi_slave_monitor.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Multi-channel AXI4 Slave Monitor sharing the independent 5-channel
//              monitoring architecture for the slave agent perspective.
// ============================================================================

`ifndef AXI_SLAVE_MONITOR_SV
`define AXI_SLAVE_MONITOR_SV

class axi_slave_monitor extends axi_master_monitor;
    `uvm_component_utils(axi_slave_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass : axi_slave_monitor

`endif // AXI_SLAVE_MONITOR_SV
