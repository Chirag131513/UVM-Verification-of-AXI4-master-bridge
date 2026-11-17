// ============================================================================
// File: axi_coverage_closure_test.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Systematic Coverage Closure Test executing all burst lengths
//              (1 to 256 beats), all unaligned offsets, 4KB page borders,
//              strobe patterns, and error responses to achieve 100% functional coverage.
// ============================================================================

`ifndef AXI_COVERAGE_CLOSURE_TEST_SV
`define AXI_COVERAGE_CLOSURE_TEST_SV

class axi_coverage_closure_test extends axi_base_test;
    `uvm_component_utils(axi_coverage_closure_test)

    function new(string name = "axi_coverage_closure_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_coverage_vseq vseq;
        super.run_phase(phase);
        phase.raise_objection(this);

        `uvm_info("TEST", "Starting axi_coverage_closure_test: Systematic stimulus for 100% coverage...", UVM_LOW)
        vseq = axi_coverage_vseq::type_id::create("vseq");
        vseq.start(env.v_sqr);

        phase.drop_objection(this);
    endtask
endclass : axi_coverage_closure_test

`endif // AXI_COVERAGE_CLOSURE_TEST_SV
