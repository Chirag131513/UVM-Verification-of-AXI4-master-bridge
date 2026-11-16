// ============================================================================
// File: axi_directed_test.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Directed Tests targeting specific AXI4 burst modes, unaligned transfers,
//              4KB boundary crossings, RAW hazards, and maximum 256-beat bursts.
// ============================================================================

`ifndef AXI_DIRECTED_TEST_SV
`define AXI_DIRECTED_TEST_SV

// ----------------------------------------------------------------------------
// Test 1: axi_directed_test (Comprehensive Directed Sweep)
// ----------------------------------------------------------------------------
class axi_directed_test extends axi_base_test;
    `uvm_component_utils(axi_directed_test)

    function new(string name = "axi_directed_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_basic_vseq vseq;
        super.run_phase(phase);
        phase.raise_objection(this);

        `uvm_info("TEST", "Starting axi_directed_test execution...", UVM_LOW)
        vseq = axi_basic_vseq::type_id::create("vseq");
        vseq.start(env.v_sqr);

        phase.drop_objection(this);
    endtask
endclass : axi_directed_test


// ----------------------------------------------------------------------------
// Test 2: axi_single_beat_test (Corner cases: WLAST on 1-beat & zero data)
// ----------------------------------------------------------------------------
class axi_single_beat_test extends axi_base_test;
    `uvm_component_utils(axi_single_beat_test)

    function new(string name = "axi_single_beat_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_base_vseq vseq;
        super.run_phase(phase);
        phase.raise_objection(this);

        `uvm_info("TEST", "Starting axi_single_beat_test: Verifying WLAST on 1-beat burst (AWLEN=0)...", UVM_LOW)
        vseq = axi_base_vseq::type_id::create("vseq");

        // Issue 1-byte write (results in single-beat burst AWLEN=0)
        vseq.send_user_write(32'h1000_0000, 1, 2'b01);
        #100ns;

        // Issue 1-byte read
        vseq.send_user_read(32'h1000_0000, 1, 2'b01);
        #100ns;

        phase.drop_objection(this);
    endtask
endclass : axi_single_beat_test


// ----------------------------------------------------------------------------
// Test 3: axi_burst_256_test (Demonstrating Maximum Legal 256-beat INCR burst)
// ----------------------------------------------------------------------------
class axi_burst_256_test extends axi_base_test;
    `uvm_component_utils(axi_burst_256_test)

    function new(string name = "axi_burst_256_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_base_vseq vseq;
        super.run_phase(phase);
        phase.raise_objection(this);

        `uvm_info("TEST", "Starting axi_burst_256_test: 1024 bytes -> 256-beat AXI4 INCR burst (AxLEN=255)...", UVM_LOW)
        vseq = axi_base_vseq::type_id::create("vseq");

        // 1024 bytes aligned to 4KB page boundary = exactly 256 beats (AxLEN = 255)
        vseq.send_user_write(32'h1000_0000, 1024, 2'b01);
        #2000ns;

        vseq.send_user_read(32'h1000_0000, 1024, 2'b01);
        #2000ns;

        phase.drop_objection(this);
    endtask
endclass : axi_burst_256_test


// ----------------------------------------------------------------------------
// Test 4: axi_boundary_test (4KB Boundary Crossing and Burst Splitting)
// ----------------------------------------------------------------------------
class axi_boundary_test extends axi_base_test;
    `uvm_component_utils(axi_boundary_test)

    function new(string name = "axi_boundary_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_boundary_vseq vseq;
        super.run_phase(phase);
        phase.raise_objection(this);

        `uvm_info("TEST", "Starting axi_boundary_test: Testing 4KB splitting logic...", UVM_LOW)
        vseq = axi_boundary_vseq::type_id::create("vseq");
        vseq.start(env.v_sqr);

        phase.drop_objection(this);
    endtask
endclass : axi_boundary_test

`endif // AXI_DIRECTED_TEST_SV
