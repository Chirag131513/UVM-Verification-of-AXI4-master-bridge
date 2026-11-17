// ============================================================================
// File: axi_regression_test.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Master Regression Test executing all verification phases:
//              1. Directed Sanity & Readback Verification
//              2. 4KB Page Boundary Crossing & Address Splitting
//              3. Constrained-Randomized Burst Streams
//              4. Concurrent Full-Duplex Read/Write Streams
//              5. High-Throughput Pipelined Bursts for Bus Utilization
//              6. Systematic 1 to 256 Beat Sweeps & Strobe Coverage Closure
// ============================================================================

`ifndef AXI_REGRESSION_TEST_SV
`define AXI_REGRESSION_TEST_SV

class axi_regression_test extends axi_base_test;
    `uvm_component_utils(axi_regression_test)

    function new(string name = "axi_regression_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_basic_vseq      basic_vseq;
        axi_boundary_vseq   boundary_vseq;
        axi_random_vseq     rand_vseq;
        axi_concurrent_vseq conc_vseq;
        axi_throughput_vseq tput_vseq;
        axi_coverage_vseq   cov_vseq;

        super.run_phase(phase);
        phase.raise_objection(this);

        `uvm_info("REGRESSION", "=================================================================", UVM_LOW)
        `uvm_info("REGRESSION", "         STARTING FULL MASTER AXI4 REGRESSION SUITE              ", UVM_LOW)
        `uvm_info("REGRESSION", "=================================================================", UVM_LOW)

        // Stage 1: Basic Sanity
        `uvm_info("REGRESSION", "--> Stage 1: Directed Sanity & Readback Verification...", UVM_LOW)
        basic_vseq = axi_basic_vseq::type_id::create("basic_vseq");
        basic_vseq.start(env.v_sqr);
        #100ns;

        // Stage 2: 4KB Boundary Crossing
        `uvm_info("REGRESSION", "--> Stage 2: 4KB Page Boundary Splitting...", UVM_LOW)
        boundary_vseq = axi_boundary_vseq::type_id::create("boundary_vseq");
        boundary_vseq.start(env.v_sqr);
        #100ns;

        // Stage 3: Constrained-Random Bursts
        `uvm_info("REGRESSION", "--> Stage 3: Constrained-Random Stimulus...", UVM_LOW)
        rand_vseq = axi_random_vseq::type_id::create("rand_vseq");
        rand_vseq.num_trans = 15;
        rand_vseq.start(env.v_sqr);
        #100ns;

        // Stage 4: Concurrent Full-Duplex Traffic
        `uvm_info("REGRESSION", "--> Stage 4: Concurrent Read/Write Streams...", UVM_LOW)
        conc_vseq = axi_concurrent_vseq::type_id::create("conc_vseq");
        conc_vseq.start(env.v_sqr);
        #100ns;

        // Stage 5: Sustained High Throughput
        `uvm_info("REGRESSION", "--> Stage 5: High-Throughput Bus Utilization...", UVM_LOW)
        tput_vseq = axi_throughput_vseq::type_id::create("tput_vseq");
        tput_vseq.num_bursts = 10;
        tput_vseq.start(env.v_sqr);
        #100ns;

        // Stage 6: Full Coverage Closure (1 to 256 beats, strobes, offsets, error responses)
        `uvm_info("REGRESSION", "--> Stage 6: Full Coverage Closure Sweeps (1 to 256 beats)...", UVM_LOW)
        cov_vseq = axi_coverage_vseq::type_id::create("cov_vseq");
        cov_vseq.start(env.v_sqr);
        #200ns;

        `uvm_info("REGRESSION", "=================================================================", UVM_LOW)
        `uvm_info("REGRESSION", "         COMPLETED FULL MASTER AXI4 REGRESSION SUITE             ", UVM_LOW)
        `uvm_info("REGRESSION", "=================================================================", UVM_LOW)

        phase.drop_objection(this);
    endtask
endclass : axi_regression_test

`endif // AXI_REGRESSION_TEST_SV
