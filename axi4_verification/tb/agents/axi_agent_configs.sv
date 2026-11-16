// ============================================================================
// File: axi_agent_configs.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Configuration descriptors for AXI Master, AXI Slave, and User Agents.
// ============================================================================

`ifndef AXI_AGENT_CONFIGS_SV
`define AXI_AGENT_CONFIGS_SV

class axi_master_config extends uvm_object;
    `uvm_object_utils(axi_master_config)

    uvm_active_passive_enum is_active = UVM_PASSIVE; // Passive when DUT is Master
    axi_timing_profile_e    timing_profile = PROFILE_LOW_LATENCY;

    function new(string name = "axi_master_config");
        super.new(name);
    endfunction
endclass : axi_master_config


class axi_slave_config extends uvm_object;
    `uvm_object_utils(axi_slave_config)

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    axi_timing_profile_e    timing_profile = PROFILE_LOW_LATENCY;
    bit                     auto_response = 1'b1;
    axi_resp_e              default_resp  = AXI_RESP_OKAY;

    function new(string name = "axi_slave_config");
        super.new(name);
    endfunction
endclass : axi_slave_config


class user_agent_config extends uvm_object;
    `uvm_object_utils(user_agent_config)

    uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name = "user_agent_config");
        super.new(name);
    endfunction
endclass : user_agent_config


// ----------------------------------------------------------------------------
// Mailbox Wrapper Classes for UVM Config DB Compatibility
// ----------------------------------------------------------------------------
class axi_cmd_mbx_wrapper extends uvm_object;
    `uvm_object_utils(axi_cmd_mbx_wrapper)
    axi_cmd_mbx_t mbx;
    function new(string name = "axi_cmd_mbx_wrapper");
        super.new(name);
        mbx = new();
    endfunction
endclass : axi_cmd_mbx_wrapper

class axi_ev_mbx_wrapper extends uvm_object;
    `uvm_object_utils(axi_ev_mbx_wrapper)
    axi_ev_mbx_t mbx;
    function new(string name = "axi_ev_mbx_wrapper");
        super.new(name);
        mbx = new();
    endfunction
endclass : axi_ev_mbx_wrapper

class user_cmd_mbx_wrapper extends uvm_object;
    `uvm_object_utils(user_cmd_mbx_wrapper)
    user_cmd_mbx_t mbx;
    function new(string name = "user_cmd_mbx_wrapper");
        super.new(name);
        mbx = new();
    endfunction
endclass : user_cmd_mbx_wrapper

class user_ev_mbx_wrapper extends uvm_object;
    `uvm_object_utils(user_ev_mbx_wrapper)
    user_ev_mbx_t mbx;
    function new(string name = "user_ev_mbx_wrapper");
        super.new(name);
        mbx = new();
    endfunction
endclass : user_ev_mbx_wrapper

`endif // AXI_AGENT_CONFIGS_SV
