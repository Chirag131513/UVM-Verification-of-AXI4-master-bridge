// ============================================================================
// File: axi_functional_coverage.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Comprehensive Functional Coverage Model for AMBA AXI4 Protocol
//              sampling independently from channel monitors.
// ============================================================================

`ifndef AXI_FUNCTIONAL_COVERAGE_SV
`define AXI_FUNCTIONAL_COVERAGE_SV

class axi_functional_coverage extends uvm_subscriber #(axi_transaction);
    `uvm_component_utils(axi_functional_coverage)

    // Current transaction cache for sampling
    axi_transaction cur_tx;

    // ------------------------------------------------------------------------
    // Covergroup 1: Transaction & Protocol Parameters
    // ------------------------------------------------------------------------
    covergroup cg_axi_trans;
        option.per_instance = 1;
        option.name = "cg_axi_trans";
        option.comment = "AXI4 Protocol & Transaction Coverage";

        // Operation Direction
        cp_direction: coverpoint cur_tx.op_type {
            bins WRITE = {AXI_OP_WRITE};
            bins READ  = {AXI_OP_READ};
        }

        // Burst Type
        cp_burst_type: coverpoint cur_tx.burst {
            bins FIXED = {AXI_BURST_FIXED};
            bins INCR  = {AXI_BURST_INCR};
            bins WRAP  = {AXI_BURST_WRAP};
        }

        // Burst Length (AxLEN: 0 to 255 beats)
        cp_burst_len: coverpoint cur_tx.len {
            bins SINGLE_BEAT   = {8'd0};
            bins SHORT_BURST   = {[8'd1 : 8'd14]};
            bins BURST_16_BEAT = {8'd15};
            bins MEDIUM_BURST  = {[8'd16 : 8'd63]};
            bins LONG_BURST    = {[8'd64 : 8'd254]};
            bins MAX_256_BEAT  = {8'd255};
        }

        // Transfer Size
        cp_size: coverpoint cur_tx.size {
            bins BYTE_1 = {AXI_SIZE_1_BYTE};
            bins BYTE_2 = {AXI_SIZE_2_BYTES};
            bins BYTE_4 = {AXI_SIZE_4_BYTES};
        }

        // Start Address Alignment (Lower 2 bits for 32-bit bus)
        cp_addr_alignment: coverpoint cur_tx.addr[1:0] {
            bins ALIGNED_0 = {2'b00};
            bins OFFSET_1  = {2'b01};
            bins OFFSET_2  = {2'b10};
            bins OFFSET_3  = {2'b11};
        }

        // Proximity to 4KB page boundary
        cp_4kb_proximity: coverpoint cur_tx.addr[11:0] {
            bins FAR_FROM_4KB   = {[12'h000 : 12'hF00]};
            bins NEAR_4KB_START = {[12'hF01 : 12'hFDF]};
            bins AT_4KB_BORDER  = {[12'hFE0 : 12'hFFF]};
        }

        // Response Code
        cp_response: coverpoint cur_tx.bresp {
            bins OKAY   = {AXI_RESP_OKAY};
            bins SLVERR = {AXI_RESP_SLVERR};
            bins DECERR = {AXI_RESP_DECERR};
        }

        // Cross Coverage
        cross_dir_x_burst: cross cp_direction, cp_burst_type;
        cross_burst_x_len: cross cp_burst_type, cp_burst_len {
            // FIXED bursts are illegal beyond 16 beats in AXI4
            ignore_bins fixed_long = binsof(cp_burst_type) intersect {AXI_BURST_FIXED} &&
                                     binsof(cp_burst_len) intersect {[8'd16 : 8'd63], [8'd64 : 8'd254], 8'd255};
            // WRAP bursts are legal only for 2, 4, 8, 16 beats
            ignore_bins wrap_illegal = binsof(cp_burst_type) intersect {AXI_BURST_WRAP} &&
                                       binsof(cp_burst_len) intersect {8'd0, [8'd16 : 8'd63], [8'd64 : 8'd254], 8'd255};
        }
        cross_dir_x_resp: cross cp_direction, cp_response;
    endgroup

    // ------------------------------------------------------------------------
    // Covergroup 2: Write Strobes & Data Patterns
    // ------------------------------------------------------------------------
    covergroup cg_data_strobes;
        option.per_instance = 1;
        option.name = "cg_data_strobes";

        cp_addr_alignment_w: coverpoint cur_tx.addr[1:0] {
            bins ALIGNED_0 = {2'b00};
            bins OFFSET_1  = {2'b01};
            bins OFFSET_2  = {2'b10};
            bins OFFSET_3  = {2'b11};
        }

        cp_wstrb_first_beat: coverpoint cur_tx.wstrb[0] {
            bins FULL_STROBE    = {4'b1111};
            bins SINGLE_LANE_0  = {4'b0001};
            bins SINGLE_LANE_1  = {4'b0010};
            bins SINGLE_LANE_2  = {4'b0100};
            bins SINGLE_LANE_3  = {4'b1000};
            bins PARTIAL_UPPER  = {4'b1100, 4'b1110};
            bins PARTIAL_LOWER  = {4'b0011, 4'b0111};
        }

        cross_align_x_strb: cross cp_addr_alignment_w, cp_wstrb_first_beat;
    endgroup

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_axi_trans    = new();
        cg_data_strobes = new();
    endfunction

    // ------------------------------------------------------------------------
    // Subscriber Write Implementation
    // ------------------------------------------------------------------------
    virtual function void write(axi_transaction t);
        cur_tx = t;
        cg_axi_trans.sample();
        if (cur_tx.op_type == AXI_OP_WRITE && cur_tx.wstrb.size() > 0) begin
            cg_data_strobes.sample();
        end
    endfunction

    // ------------------------------------------------------------------------
    // Report Phase
    // ------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV", "=========================================================", UVM_LOW)
        `uvm_info("COV", "           FUNCTIONAL COVERAGE MODEL REPORT              ", UVM_LOW)
        `uvm_info("COV", "=========================================================", UVM_LOW)
        `uvm_info("COV", $sformatf("  Transaction & Protocol Coverage : %0.2f %%", cg_axi_trans.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  Data & Byte Strobe Coverage     : %0.2f %%", cg_data_strobes.get_coverage()), UVM_LOW)
        `uvm_info("COV", "=========================================================", UVM_LOW)
    endfunction

endclass : axi_functional_coverage

`endif // AXI_FUNCTIONAL_COVERAGE_SV
