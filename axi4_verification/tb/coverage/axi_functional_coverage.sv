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

    bit [31:0] last_write_addr;

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
        if (t.get_name() == "aw_tx") begin
            last_write_addr = t.addr;
            cg_axi_trans.sample();
        end else if (t.get_name() == "ar_tx") begin
            cg_axi_trans.sample();
        end else if (t.get_name() == "w_tx" || t.wstrb.size() > 0) begin
            cur_tx.addr = last_write_addr;
            cg_data_strobes.sample();
        end else if (t.get_name() == "b_tx") begin
            cg_axi_trans.sample();
        end else begin
            cg_axi_trans.sample();
            if (t.wstrb.size() > 0) cg_data_strobes.sample();
        end
    endfunction

    // ------------------------------------------------------------------------
    // Report Phase: Self-contained reporting without requiring external IMC
    // ------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        real cov_trans, cov_strobes, cov_overall;
        real c_dir, c_burst, c_len, c_size, c_align, c_4kb, c_resp;
        real c_x_dir_burst, c_x_burst_len, c_x_dir_resp;
        real c_align_w, c_wstrb, c_x_align_wstrb;
        int fd;

        super.report_phase(phase);

        cov_trans   = cg_axi_trans.get_coverage();
        cov_strobes = cg_data_strobes.get_coverage();
        cov_overall = (cov_trans + cov_strobes) / 2.0;

        c_dir          = cg_axi_trans.cp_direction.get_coverage();
        c_burst        = cg_axi_trans.cp_burst_type.get_coverage();
        c_len          = cg_axi_trans.cp_burst_len.get_coverage();
        c_size         = cg_axi_trans.cp_size.get_coverage();
        c_align        = cg_axi_trans.cp_addr_alignment.get_coverage();
        c_4kb          = cg_axi_trans.cp_4kb_proximity.get_coverage();
        c_resp         = cg_axi_trans.cp_response.get_coverage();
        c_x_dir_burst  = cg_axi_trans.cross_dir_x_burst.get_coverage();
        c_x_burst_len  = cg_axi_trans.cross_burst_x_len.get_coverage();
        c_x_dir_resp   = cg_axi_trans.cross_dir_x_resp.get_coverage();

        c_align_w      = cg_data_strobes.cp_addr_alignment_w.get_coverage();
        c_wstrb        = cg_data_strobes.cp_wstrb_first_beat.get_coverage();
        c_x_align_wstrb= cg_data_strobes.cross_align_x_strb.get_coverage();

        `uvm_info("COV", "================================================================================", UVM_LOW)
        `uvm_info("COV", "                    AMBA AXI4 FUNCTIONAL COVERAGE REPORT                         ", UVM_LOW)
        `uvm_info("COV", "================================================================================", UVM_LOW)
        `uvm_info("COV", $sformatf("  TOTAL OVERALL FUNCTIONAL COVERAGE : %6.2f %%", cov_overall), UVM_LOW)
        `uvm_info("COV", "--------------------------------------------------------------------------------", UVM_LOW)
        `uvm_info("COV", $sformatf("  [1] Protocol & Transaction (cg_axi_trans)       : %6.2f %%", cov_trans), UVM_LOW)
        `uvm_info("COV", $sformatf("      * cp_direction      (WRITE, READ)           : %6.2f %%", c_dir), UVM_LOW)
        `uvm_info("COV", $sformatf("      * cp_burst_type     (FIXED, INCR, WRAP)     : %6.2f %%", c_burst), UVM_LOW)
        `uvm_info("COV", $sformatf("      * cp_burst_len      (1..256 beats)          : %6.2f %%", c_len), UVM_LOW)
        `uvm_info("COV", $sformatf("      * cp_size           (1, 2, 4 bytes)         : %6.2f %%", c_size), UVM_LOW)
        `uvm_info("COV", $sformatf("      * cp_addr_alignment (4-byte lane alignment) : %6.2f %%", c_align), UVM_LOW)
        `uvm_info("COV", $sformatf("      * cp_4kb_proximity  (4KB page boundary)     : %6.2f %%", c_4kb), UVM_LOW)
        `uvm_info("COV", $sformatf("      * cp_response       (OKAY, SLVERR, DECERR)  : %6.2f %%", c_resp), UVM_LOW)
        `uvm_info("COV", $sformatf("      * cross_dir_x_burst (Direction x Burst)     : %6.2f %%", c_x_dir_burst), UVM_LOW)
        `uvm_info("COV", $sformatf("      * cross_burst_x_len (Burst x Length legal)  : %6.2f %%", c_x_burst_len), UVM_LOW)
        `uvm_info("COV", $sformatf("      * cross_dir_x_resp  (Direction x Response)  : %6.2f %%", c_x_dir_resp), UVM_LOW)
        `uvm_info("COV", "--------------------------------------------------------------------------------", UVM_LOW)
        `uvm_info("COV", $sformatf("  [2] Data & Strobe Patterns (cg_data_strobes)    : %6.2f %%", cov_strobes), UVM_LOW)
        `uvm_info("COV", $sformatf("      * cp_addr_alignment_w (Write addr offset)   : %6.2f %%", c_align_w), UVM_LOW)
        `uvm_info("COV", $sformatf("      * cp_wstrb_first_beat (Full, single, part)  : %6.2f %%", c_wstrb), UVM_LOW)
        `uvm_info("COV", $sformatf("      * cross_align_x_strb  (Offset x Strobe)     : %6.2f %%", c_x_align_wstrb), UVM_LOW)
        `uvm_info("COV", "================================================================================", UVM_LOW)

        // Standalone text summary file
        fd = $fopen("../reports/coverage_summary.txt", "w");
        if (fd) begin
            $fdisplay(fd, "================================================================================");
            $fdisplay(fd, "               AMBA AXI4 FUNCTIONAL COVERAGE SUMMARY REPORT                    ");
            $fdisplay(fd, "================================================================================");
            $fdisplay(fd, "Generated automatically during UVM report_phase (Cadence Xcelium 22.09)");
            $fdisplay(fd, "");
            $fdisplay(fd, "OVERALL FUNCTIONAL COVERAGE: %0.2f %%\n", cov_overall);
            $fdisplay(fd, "Covergroup: cg_axi_trans (Score: %0.2f %%)", cov_trans);
            $fdisplay(fd, "  - cp_direction          : %6.2f %%", c_dir);
            $fdisplay(fd, "  - cp_burst_type         : %6.2f %%", c_burst);
            $fdisplay(fd, "  - cp_burst_len          : %6.2f %%", c_len);
            $fdisplay(fd, "  - cp_size               : %6.2f %%", c_size);
            $fdisplay(fd, "  - cp_addr_alignment     : %6.2f %%", c_align);
            $fdisplay(fd, "  - cp_4kb_proximity      : %6.2f %%", c_4kb);
            $fdisplay(fd, "  - cp_response           : %6.2f %%", c_resp);
            $fdisplay(fd, "  - cross_dir_x_burst     : %6.2f %%", c_x_dir_burst);
            $fdisplay(fd, "  - cross_burst_x_len     : %6.2f %%", c_x_burst_len);
            $fdisplay(fd, "  - cross_dir_x_resp      : %6.2f %%", c_x_dir_resp);
            $fdisplay(fd, "");
            $fdisplay(fd, "Covergroup: cg_data_strobes (Score: %0.2f %%)", cov_strobes);
            $fdisplay(fd, "  - cp_addr_alignment_w   : %6.2f %%", c_align_w);
            $fdisplay(fd, "  - cp_wstrb_first_beat   : %6.2f %%", c_wstrb);
            $fdisplay(fd, "  - cross_align_x_strb    : %6.2f %%", c_x_align_wstrb);
            $fdisplay(fd, "================================================================================");
            $fclose(fd);
        end

        // Standalone HTML report file
        fd = $fopen("../reports/coverage_report.html", "w");
        if (fd) begin
            $fdisplay(fd, "<!DOCTYPE html>");
            $fdisplay(fd, "<html><head><meta charset='UTF-8'><title>AXI4 Functional Coverage Report</title>");
            $fdisplay(fd, "<style>");
            $fdisplay(fd, "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f172a; color: #f8fafc; margin: 0; padding: 24px; }");
            $fdisplay(fd, ".card { background: #1e293b; border-radius: 12px; padding: 24px; margin-bottom: 24px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.5); }");
            $fdisplay(fd, "h1 { margin-top: 0; color: #38bdf8; font-size: 24px; }");
            $fdisplay(fd, "h2 { color: #94a3b8; font-size: 18px; margin-top: 0; border-bottom: 1px solid #334155; padding-bottom: 8px; }");
            $fdisplay(fd, ".grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; margin-bottom: 24px; }");
            $fdisplay(fd, ".kpi { background: #0f172a; padding: 16px; border-radius: 8px; border-left: 4px solid #38bdf8; }");
            $fdisplay(fd, ".kpi-title { font-size: 12px; text-transform: uppercase; color: #94a3b8; }");
            $fdisplay(fd, ".kpi-val { font-size: 28px; font-weight: bold; margin-top: 8px; color: #38bdf8; }");
            $fdisplay(fd, "table { width: 100%%; border-collapse: collapse; margin-top: 12px; }");
            $fdisplay(fd, "th, td { text-align: left; padding: 10px 14px; border-bottom: 1px solid #334155; }");
            $fdisplay(fd, "th { color: #94a3b8; font-size: 13px; text-transform: uppercase; }");
            $fdisplay(fd, ".progress-bg { background: #334155; border-radius: 6px; height: 12px; width: 140px; overflow: hidden; display: inline-block; vertical-align: middle; margin-right: 8px; }");
            $fdisplay(fd, ".progress-fill { background: #38bdf8; height: 100%%; border-radius: 6px; }");
            $fdisplay(fd, ".tag-pass { background: rgba(34,197,94,0.2); color: #4ade80; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }");
            $fdisplay(fd, ".tag-prog { background: rgba(234,179,8,0.2); color: #facc15; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }");
            $fdisplay(fd, "</style></head><body>");
            $fdisplay(fd, "<div class='card'>");
            $fdisplay(fd, "  <h1>AMBA AXI4 Functional Coverage Report</h1>");
            $fdisplay(fd, "  <p style='color: #94a3b8;'>Self-contained report generated by UVM Verification IP (Native SystemVerilog / No external tools required)</p>");
            $fdisplay(fd, "  <div class='grid'>");
            $fdisplay(fd, "    <div class='kpi'><div class='kpi-title'>Total Coverage</div><div class='kpi-val'>%0.2f %%</div></div>", cov_overall);
            $fdisplay(fd, "    <div class='kpi' style='border-color: #818cf8;'><div class='kpi-title'>Protocol Coverage</div><div class='kpi-val' style='color: #818cf8;'>%0.2f %%</div></div>", cov_trans);
            $fdisplay(fd, "    <div class='kpi' style='border-color: #34d399;'><div class='kpi-title'>Data Strobe Coverage</div><div class='kpi-val' style='color: #34d399;'>%0.2f %%</div></div>", cov_strobes);
            $fdisplay(fd, "  </div>");
            $fdisplay(fd, "</div>");
            $fdisplay(fd, "<div class='card'>");
            $fdisplay(fd, "  <h2>Covergroup: cg_axi_trans (Protocol & Transaction Model)</h2>");
            $fdisplay(fd, "  <table><thead><tr><th>Coverpoint / Cross</th><th>Description</th><th>Coverage</th><th>Progress</th><th>Status</th></tr></thead><tbody>");
            $fdisplay(fd, "    <tr><td><b>cp_direction</b></td><td>Operation Type (WRITE, READ)</td><td>%0.2f %%</td><td><div class='progress-bg'><div class='progress-fill' style='width: %0.0f%%;'></div></div></td><td><span class='%s'>%s</span></td></tr>", c_dir, c_dir, (c_dir >= 100.0 ? "tag-pass" : "tag-prog"), (c_dir >= 100.0 ? "COMPLETE" : "IN-PROGRESS"));
            $fdisplay(fd, "    <tr><td><b>cp_burst_type</b></td><td>Burst Type (FIXED, INCR, WRAP)</td><td>%0.2f %%</td><td><div class='progress-bg'><div class='progress-fill' style='width: %0.0f%%;'></div></div></td><td><span class='%s'>%s</span></td></tr>", c_burst, c_burst, (c_burst >= 100.0 ? "tag-pass" : "tag-prog"), (c_burst >= 100.0 ? "COMPLETE" : "IN-PROGRESS"));
            $fdisplay(fd, "    <tr><td><b>cp_burst_len</b></td><td>Burst Lengths (1 to 256 beats)</td><td>%0.2f %%</td><td><div class='progress-bg'><div class='progress-fill' style='width: %0.0f%%;'></div></div></td><td><span class='%s'>%s</span></td></tr>", c_len, c_len, (c_len >= 100.0 ? "tag-pass" : "tag-prog"), (c_len >= 100.0 ? "COMPLETE" : "IN-PROGRESS"));
            $fdisplay(fd, "    <tr><td><b>cp_size</b></td><td>Transfer Size (1B, 2B, 4B)</td><td>%0.2f %%</td><td><div class='progress-bg'><div class='progress-fill' style='width: %0.0f%%;'></div></div></td><td><span class='%s'>%s</span></td></tr>", c_size, c_size, (c_size >= 100.0 ? "tag-pass" : "tag-prog"), (c_size >= 100.0 ? "COMPLETE" : "IN-PROGRESS"));
            $fdisplay(fd, "    <tr><td><b>cp_addr_alignment</b></td><td>Address Alignment (0, 1, 2, 3)</td><td>%0.2f %%</td><td><div class='progress-bg'><div class='progress-fill' style='width: %0.0f%%;'></div></div></td><td><span class='%s'>%s</span></td></tr>", c_align, c_align, (c_align >= 100.0 ? "tag-pass" : "tag-prog"), (c_align >= 100.0 ? "COMPLETE" : "IN-PROGRESS"));
            $fdisplay(fd, "    <tr><td><b>cp_4kb_proximity</b></td><td>Distance from 4KB boundary</td><td>%0.2f %%</td><td><div class='progress-bg'><div class='progress-fill' style='width: %0.0f%%;'></div></div></td><td><span class='%s'>%s</span></td></tr>", c_4kb, c_4kb, (c_4kb >= 100.0 ? "tag-pass" : "tag-prog"), (c_4kb >= 100.0 ? "COMPLETE" : "IN-PROGRESS"));
            $fdisplay(fd, "    <tr><td><b>cp_response</b></td><td>Response Status (OKAY, SLVERR, DECERR)</td><td>%0.2f %%</td><td><div class='progress-bg'><div class='progress-fill' style='width: %0.0f%%;'></div></div></td><td><span class='%s'>%s</span></td></tr>", c_resp, c_resp, (c_resp >= 100.0 ? "tag-pass" : "tag-prog"), (c_resp >= 100.0 ? "COMPLETE" : "IN-PROGRESS"));
            $fdisplay(fd, "    <tr><td><b>cross_dir_x_burst</b></td><td>Direction x Burst Type</td><td>%0.2f %%</td><td><div class='progress-bg'><div class='progress-fill' style='width: %0.0f%%;'></div></div></td><td><span class='%s'>%s</span></td></tr>", c_x_dir_burst, c_x_dir_burst, (c_x_dir_burst >= 100.0 ? "tag-pass" : "tag-prog"), (c_x_dir_burst >= 100.0 ? "COMPLETE" : "IN-PROGRESS"));
            $fdisplay(fd, "    <tr><td><b>cross_burst_x_len</b></td><td>Burst Type x Legal Lengths</td><td>%0.2f %%</td><td><div class='progress-bg'><div class='progress-fill' style='width: %0.0f%%;'></div></div></td><td><span class='%s'>%s</span></td></tr>", c_x_burst_len, c_x_burst_len, (c_x_burst_len >= 100.0 ? "tag-pass" : "tag-prog"), (c_x_burst_len >= 100.0 ? "COMPLETE" : "IN-PROGRESS"));
            $fdisplay(fd, "    <tr><td><b>cross_dir_x_resp</b></td><td>Direction x Response Code</td><td>%0.2f %%</td><td><div class='progress-bg'><div class='progress-fill' style='width: %0.0f%%;'></div></div></td><td><span class='%s'>%s</span></td></tr>", c_x_dir_resp, c_x_dir_resp, (c_x_dir_resp >= 100.0 ? "tag-pass" : "tag-prog"), (c_x_dir_resp >= 100.0 ? "COMPLETE" : "IN-PROGRESS"));
            $fdisplay(fd, "  </tbody></table>");
            $fdisplay(fd, "</div>");
            $fdisplay(fd, "<div class='card'>");
            $fdisplay(fd, "  <h2>Covergroup: cg_data_strobes (Byte Strobes & Lane Activity)</h2>");
            $fdisplay(fd, "  <table><thead><tr><th>Coverpoint / Cross</th><th>Description</th><th>Coverage</th><th>Progress</th><th>Status</th></tr></thead><tbody>");
            $fdisplay(fd, "    <tr><td><b>cp_addr_alignment_w</b></td><td>Write Address Offset (0, 1, 2, 3)</td><td>%0.2f %%</td><td><div class='progress-bg'><div class='progress-fill' style='width: %0.0f%%;'></div></div></td><td><span class='%s'>%s</span></td></tr>", c_align_w, c_align_w, (c_align_w >= 100.0 ? "tag-pass" : "tag-prog"), (c_align_w >= 100.0 ? "COMPLETE" : "IN-PROGRESS"));
            $fdisplay(fd, "    <tr><td><b>cp_wstrb_first_beat</b></td><td>First Beat Strobe Patterns (0xF, 0x1, 0x2, 0x4, 0x8...)</td><td>%0.2f %%</td><td><div class='progress-bg'><div class='progress-fill' style='width: %0.0f%%;'></div></div></td><td><span class='%s'>%s</span></td></tr>", c_wstrb, c_wstrb, (c_wstrb >= 100.0 ? "tag-pass" : "tag-prog"), (c_wstrb >= 100.0 ? "COMPLETE" : "IN-PROGRESS"));
            $fdisplay(fd, "    <tr><td><b>cross_align_x_strb</b></td><td>Offset x Strobe Combination</td><td>%0.2f %%</td><td><div class='progress-bg'><div class='progress-fill' style='width: %0.0f%%;'></div></div></td><td><span class='%s'>%s</span></td></tr>", c_x_align_wstrb, c_x_align_wstrb, (c_x_align_wstrb >= 100.0 ? "tag-pass" : "tag-prog"), (c_x_align_wstrb >= 100.0 ? "COMPLETE" : "IN-PROGRESS"));
            $fdisplay(fd, "  </tbody></table>");
            $fdisplay(fd, "</div></body></html>");
            $fclose(fd);
        end
    endfunction

endclass : axi_functional_coverage

`endif // AXI_FUNCTIONAL_COVERAGE_SV
