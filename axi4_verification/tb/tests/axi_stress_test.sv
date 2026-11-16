// ============================================================================
// File: axi_stress_test.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Stress & Performance Tests executing continuous pipelined bursts,
//              measuring peak bus utilization (targeting 95.45%), and verifying
//              latency invariance across Profiles A, B, and C.
// ============================================================================

`ifndef AXI_STRESS_TEST_SV
`define AXI_STRESS_TEST_SV

// ----------------------------------------------------------------------------
// Test 1: axi_stress_test (Backpressure & Latency Invariance across A/B/C)
// ----------------------------------------------------------------------------
class axi_stress_test extends axi_base_test;
    `uvm_component_utils(axi_stress_test)

    function new(string name = "axi_stress_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_backpressure_vseq vseq;
        super.run_phase(phase);
        phase.raise_objection(this);

        `uvm_info("TEST", "Starting axi_stress_test: Latency invariance across Profiles A, B, C...", UVM_LOW)
        vseq = axi_backpressure_vseq::type_id::create("vseq");
        vseq.start(env.v_sqr);

        phase.drop_objection(this);
    endtask
endclass : axi_stress_test


// ----------------------------------------------------------------------------
// Test 2: axi_concurrent_test (True concurrent reads and writes)
// ----------------------------------------------------------------------------
class axi_concurrent_test extends axi_base_test;
    `uvm_component_utils(axi_concurrent_test)

    function new(string name = "axi_concurrent_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_concurrent_vseq vseq;
        super.run_phase(phase);
        phase.raise_objection(this);

        `uvm_info("TEST", "Starting axi_concurrent_test: Full duplex concurrent read/write traffic...", UVM_LOW)
        vseq = axi_concurrent_vseq::type_id::create("vseq");
        vseq.start(env.v_sqr);

        phase.drop_objection(this);
    endtask
endclass : axi_concurrent_test


// ----------------------------------------------------------------------------
// Test 3: axi_throughput_test (Targeting up to 95.45% bus utilization)
// ----------------------------------------------------------------------------
class axi_throughput_test extends axi_base_test;
    `uvm_component_utils(axi_throughput_test)

    function new(string name = "axi_throughput_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_throughput_vseq vseq;
        super.run_phase(phase);
        phase.raise_objection(this);

        `uvm_info("TEST", "Starting axi_throughput_test: Sustained back-to-back pipeline bursts...", UVM_LOW)
        vseq = axi_throughput_vseq::type_id::create("vseq");
        vseq.num_bursts = 20; // Sustained stream
        vseq.start(env.v_sqr);

        phase.drop_objection(this);
    endtask
endclass : axi_throughput_test

`endif // AXI_STRESS_TEST_SV
