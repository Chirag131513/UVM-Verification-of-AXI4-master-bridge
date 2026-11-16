// ============================================================================
// File: axi_base_test.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: UVM Base Test establishing environment, topology printing,
//              drain times, and final pass/fail regression certification.
// ============================================================================

`ifndef AXI_BASE_TEST_SV
`define AXI_BASE_TEST_SV

class axi_base_test extends uvm_test;
    `uvm_component_utils(axi_base_test)

    axi_env env;
    axi_env_config env_cfg;

    function new(string name = "axi_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env_cfg = axi_env_config::type_id::create("env_cfg");
        uvm_config_db#(axi_env_config)::set(this, "env", "cfg", env_cfg);
        env = axi_env::type_id::create("env", this);
        `uvm_info("BASE_TEST", "Build phase completed.", UVM_HIGH)
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("BASE_TEST", "Testbench Topology:", UVM_LOW)
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.phase_done.set_drain_time(this, 100ns);
    endtask

    virtual function void report_phase(uvm_phase phase);
        uvm_report_server svr;
        super.report_phase(phase);
        svr = uvm_report_server::get_server();

        `uvm_info("BASE_TEST", "=========================================================", UVM_LOW)
        `uvm_info("BASE_TEST", "                FINAL REGRESSION SUMMARY                 ", UVM_LOW)
        `uvm_info("BASE_TEST", "=========================================================", UVM_LOW)
        `uvm_info("BASE_TEST", $sformatf("  TOTAL UVM ERRORS   : %0d", svr.get_severity_count(UVM_ERROR)), UVM_LOW)
        `uvm_info("BASE_TEST", $sformatf("  TOTAL UVM FATALS   : %0d", svr.get_severity_count(UVM_FATAL)), UVM_LOW)

        if (svr.get_severity_count(UVM_ERROR) == 0 && svr.get_severity_count(UVM_FATAL) == 0) begin
            `uvm_info("BASE_TEST", "  SIMULATION RESULT  : [PASSED]", UVM_LOW)
        end else begin
            `uvm_info("BASE_TEST", "  SIMULATION RESULT  : [FAILED]", UVM_LOW)
        end
        `uvm_info("BASE_TEST", "=========================================================", UVM_LOW)
    endfunction

endclass : axi_base_test

`endif // AXI_BASE_TEST_SV
