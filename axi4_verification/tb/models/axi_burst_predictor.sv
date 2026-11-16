// ============================================================================
// File: axi_burst_predictor.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Independent Golden Model for AXI4 burst address progression,
//              wrap boundary calculations, 4KB page splitting, and beat lengths.
// ============================================================================

`ifndef AXI_BURST_PREDICTOR_SV
`define AXI_BURST_PREDICTOR_SV

class axi_burst_predictor extends uvm_object;
    `uvm_object_utils(axi_burst_predictor)

    function new(string name = "axi_burst_predictor");
        super.new(name);
    endfunction

    // ------------------------------------------------------------------------
    // Predicts full sequence of beat addresses for a given burst
    // ------------------------------------------------------------------------
    function void predict_burst_addresses(
        input  bit [31:0]   start_addr,
        input  bit [7:0]    len,
        input  axi_size_e   size,
        input  axi_burst_e  burst,
        output bit [31:0]   addrs[]
    );
        int unsigned num_beats;
        bit [31:0] curr_addr;
        bit [31:0] wrap_lower, wrap_upper;

        num_beats = int'(len) + 1;
        addrs = new[num_beats];
        curr_addr = start_addr;

        if (burst == AXI_BURST_WRAP) begin
            get_wrap_bounds(start_addr, len, size, wrap_lower, wrap_upper);
        end

        for (int i = 0; i < num_beats; i++) begin
            addrs[i] = curr_addr;
            curr_addr = get_next_beat_addr(curr_addr, len, size, burst, wrap_lower, wrap_upper);
        end
    endfunction

    // ------------------------------------------------------------------------
    // Predicts how a user byte transfer is decomposed into AXI bursts
    // ------------------------------------------------------------------------
    function void predict_user_split(
        input  bit [31:0]  start_addr,
        input  bit [31:0]  total_bytes,
        input  bit [1:0]   user_burst,
        output bit [31:0]  burst_addrs[$],
        output bit [7:0]   burst_lens[$]
    );
        bit [31:0] curr_addr;
        bit [31:0] rem_bytes;
        int unsigned bytes_per_beat;

        bytes_per_beat = 4; // 32-bit data bus
        curr_addr = start_addr;
        rem_bytes = total_bytes;

        while (rem_bytes > 0) begin
            bit [12:0] bytes_to_4k;
            bit [31:0] max_burst_bytes;
            bit [31:0] burst_bytes;
            bit [31:0] eff_bytes;
            bit [7:0]  axi_len;

            bytes_to_4k = 13'd4096 - curr_addr[11:0];
            max_burst_bytes = 256 * bytes_per_beat; // Max 256 beats

            burst_bytes = (rem_bytes < bytes_to_4k) ? rem_bytes : bytes_to_4k;
            if (burst_bytes > max_burst_bytes) burst_bytes = max_burst_bytes;

            // Account for unaligned start offset on first burst
            if (burst_addrs.size() == 0) begin
                eff_bytes = burst_bytes + curr_addr[1:0];
            end else begin
                eff_bytes = burst_bytes;
            end

            axi_len = ((eff_bytes + bytes_per_beat - 1) / bytes_per_beat) - 1;

            burst_addrs.push_back(curr_addr);
            burst_lens.push_back(axi_len);

            if (user_burst != 2'b00) begin
                curr_addr = curr_addr + burst_bytes;
            end
            rem_bytes = rem_bytes - burst_bytes;
        end
    endfunction

endclass : axi_burst_predictor

`endif // AXI_BURST_PREDICTOR_SV
