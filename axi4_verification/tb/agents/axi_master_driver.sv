// ============================================================================
// File: axi_master_driver.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: AXI4 Master Driver. Configured passive when the DUT is Master
//              to avoid multi-driver conflicts; active when VIP is initiator.
// ============================================================================

`ifndef AXI_MASTER_DRIVER_SV
`define AXI_MASTER_DRIVER_SV

class axi_master_driver extends uvm_driver #(axi_transaction);
    `uvm_component_utils(axi_master_driver)

    axi_master_config cfg;
    axi_cmd_mbx_t     uvm_to_bfm;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(axi_master_config)::get(this, "", "cfg", cfg)) begin
            cfg = axi_master_config::type_id::create("cfg");
        end
        // Only fetch mailbox if active
        if (cfg.is_active == UVM_ACTIVE) begin
            if (!uvm_config_db#(axi_cmd_mbx_t)::get(this, "", "uvm_to_bfm", uvm_to_bfm)) begin
                `uvm_fatal("MST_DRV", "uvm_to_bfm mailbox not found")
            end
        end
    endfunction

    task run_phase(uvm_phase phase);
        // Passive mode: do nothing, let DUT drive bus
        if (cfg.is_active == UVM_PASSIVE) return;

        forever begin
            seq_item_port.get_next_item(req);
            // Drive active transactions if configured
            seq_item_port.item_done();
        end
    endtask

endclass : axi_master_driver

`endif // AXI_MASTER_DRIVER_SV
