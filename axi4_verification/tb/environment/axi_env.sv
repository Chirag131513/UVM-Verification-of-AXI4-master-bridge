// ============================================================================
// File: axi_env.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: UVM Environment instantiating Master, Slave, and User agents,
//              virtual sequencer, dual-oracle scoreboard, coverage collector,
//              and bus utilization performance monitor.
// ============================================================================

`ifndef AXI_ENV_SV
`define AXI_ENV_SV

class axi_env extends uvm_env;
    `uvm_component_utils(axi_env)

    axi_env_config           cfg;
    axi_master_agent         master_agent;
    axi_slave_agent          slave_agent;
    user_agent               user_agent_inst;
    axi_virtual_sequencer    v_sqr;
    axi_scoreboard           scoreboard;
    axi_functional_coverage  coverage_inst;
    axi_performance_monitor  perf_mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(axi_env_config)::get(this, "", "cfg", cfg)) begin
            cfg = axi_env_config::type_id::create("cfg");
        end

        // Pass configs down
        uvm_config_db#(axi_master_config)::set(this, "master_agent*", "cfg", cfg.master_cfg);
        uvm_config_db#(axi_slave_config)::set(this,  "slave_agent*",  "cfg", cfg.slave_cfg);
        uvm_config_db#(user_agent_config)::set(this, "user_agent_inst*", "cfg", cfg.user_cfg);

        master_agent    = axi_master_agent::type_id::create("master_agent", this);
        slave_agent     = axi_slave_agent::type_id::create("slave_agent", this);
        user_agent_inst = user_agent::type_id::create("user_agent_inst", this);
        v_sqr           = axi_virtual_sequencer::type_id::create("v_sqr", this);

        if (cfg.has_scoreboard) begin
            scoreboard = axi_scoreboard::type_id::create("scoreboard", this);
        end
        if (cfg.has_coverage) begin
            coverage_inst = axi_functional_coverage::type_id::create("coverage_inst", this);
        end
        if (cfg.has_perf_mon) begin
            perf_mon = axi_performance_monitor::type_id::create("perf_mon", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect Virtual Sequencer sub-sequencers
        if (cfg.master_cfg.is_active == UVM_ACTIVE) begin
            v_sqr.mst_sqr = master_agent.sqr;
        end
        if (cfg.slave_cfg.is_active == UVM_ACTIVE) begin
            v_sqr.slv_sqr = slave_agent.sqr;
        end
        if (cfg.user_cfg.is_active == UVM_ACTIVE) begin
            v_sqr.usr_sqr = user_agent_inst.sqr;
        end

        // Connect independent channel monitors to Protocol Scoreboard
        if (cfg.has_scoreboard) begin
            master_agent.mon.aw_ap.connect(scoreboard.protocol_sbd.aw_export);
            master_agent.mon.w_ap.connect(scoreboard.protocol_sbd.w_export);
            master_agent.mon.b_ap.connect(scoreboard.protocol_sbd.b_export);
            master_agent.mon.ar_ap.connect(scoreboard.protocol_sbd.ar_export);
            master_agent.mon.r_ap.connect(scoreboard.protocol_sbd.r_export);

            // Connect User monitor to Functional Memory Scoreboard
            user_agent_inst.mon.item_collected_port.connect(scoreboard.memory_sbd.usr_export);
            master_agent.mon.w_ap.connect(scoreboard.memory_sbd.bus_w_export);
        end

        // Connect Coverage Model
        if (cfg.has_coverage) begin
            master_agent.mon.aw_ap.connect(coverage_inst.analysis_export);
            master_agent.mon.ar_ap.connect(coverage_inst.analysis_export);
            master_agent.mon.w_ap.connect(coverage_inst.analysis_export);
            master_agent.mon.b_ap.connect(coverage_inst.analysis_export);
            master_agent.mon.r_ap.connect(coverage_inst.analysis_export);
        end
    endfunction

endclass : axi_env

`endif // AXI_ENV_SV
