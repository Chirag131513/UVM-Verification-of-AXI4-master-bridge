// ============================================================================
// File: axi_random_test.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Constrained-Random Test exercising randomized bursts, unaligned
//              addresses, variable payload sizes, and response delays.
// ============================================================================

`ifndef AXI_RANDOM_TEST_SV
`define AXI_RANDOM_TEST_SV

class axi_random_test extends axi_base_test;
    `uvm_component_utils(axi_random_test)

    function new(string name = "axi_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_random_vseq vseq;
        super.run_phase(phase);
        phase.raise_objection(this);

        `uvm_info("TEST", "Starting axi_random_test: Running 20 randomized transactions...", UVM_LOW)
        vseq = axi_random_vseq::type_id::create("vseq");
        vseq.num_trans = 25;
        vseq.start(env.v_sqr);

        phase.drop_objection(this);
    endtask
endclass : axi_random_test

`endif // AXI_RANDOM_TEST_SV
