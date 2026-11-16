// ============================================================================
// File: axi_env_config.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Top-level Environment Configuration class.
// ============================================================================

`ifndef AXI_ENV_CONFIG_SV
`define AXI_ENV_CONFIG_SV

class axi_env_config extends uvm_object;
    `uvm_object_utils(axi_env_config)

    axi_master_config master_cfg;
    axi_slave_config  slave_cfg;
    user_agent_config user_cfg;

    bit has_scoreboard = 1'b1;
    bit has_coverage   = 1'b1;
    bit has_perf_mon   = 1'b1;

    function new(string name = "axi_env_config");
        super.new(name);
        master_cfg = axi_master_config::type_id::create("master_cfg");
        slave_cfg  = axi_slave_config::type_id::create("slave_cfg");
        user_cfg   = user_agent_config::type_id::create("user_cfg");
    endfunction

endclass : axi_env_config

`endif // AXI_ENV_CONFIG_SV
