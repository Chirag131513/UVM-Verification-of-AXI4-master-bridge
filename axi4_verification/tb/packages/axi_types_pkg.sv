// ============================================================================
// File: axi_types_pkg.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Type definitions, enums, structs for BFM mailboxes, and
//              utility arithmetic functions for AXI4 compliance.
// ============================================================================

`ifndef AXI_TYPES_PKG_SV
`define AXI_TYPES_PKG_SV

`timescale 1ns/1ps

package axi_types_pkg;

    // ------------------------------------------------------------------------
    // Standard AXI4 Protocol Enums
    // ------------------------------------------------------------------------
    typedef enum bit [1:0] {
        AXI_BURST_FIXED    = 2'b00,
        AXI_BURST_INCR     = 2'b01,
        AXI_BURST_WRAP     = 2'b10,
        AXI_BURST_RESERVED = 2'b11
    } axi_burst_e;

    typedef enum bit [1:0] {
        AXI_RESP_OKAY   = 2'b00,
        AXI_RESP_EXOKAY = 2'b01,
        AXI_RESP_SLVERR = 2'b10,
        AXI_RESP_DECERR = 2'b11
    } axi_resp_e;

    typedef enum bit [2:0] {
        AXI_SIZE_1_BYTE   = 3'b000,
        AXI_SIZE_2_BYTES  = 3'b001,
        AXI_SIZE_4_BYTES  = 3'b010,
        AXI_SIZE_8_BYTES  = 3'b011,
        AXI_SIZE_16_BYTES = 3'b100,
        AXI_SIZE_32_BYTES = 3'b101,
        AXI_SIZE_64_BYTES = 3'b110,
        AXI_SIZE_128_BYTES= 3'b111
    } axi_size_e;

    typedef enum bit [2:0] {
        AXI_CH_AW   = 3'b000,
        AXI_CH_W    = 3'b001,
        AXI_CH_B    = 3'b010,
        AXI_CH_AR   = 3'b011,
        AXI_CH_R    = 3'b100,
        AXI_CH_USER = 3'b101
    } axi_channel_e;

    typedef enum bit {
        AXI_OP_WRITE = 1'b0,
        AXI_OP_READ  = 1'b1
    } axi_op_e;

    // Timing Profile for Latency Invariance & Backpressure
    typedef enum bit [1:0] {
        PROFILE_LOW_LATENCY   = 2'b00,
        PROFILE_RANDOM_DELAY  = 2'b01,
        PROFILE_STRESS_STALL  = 2'b10
    } axi_timing_profile_e;

    // Global Target Response Override for Systematic Coverage & Error Closure
    axi_resp_e global_target_resp = AXI_RESP_OKAY;

    // ------------------------------------------------------------------------
    // BFM Mailbox Communication Structures
    // ------------------------------------------------------------------------
    
    // Command issued from UVM Driver to BFM
    typedef struct {
        axi_channel_e         channel_id;
        axi_op_e              op_type;
        bit [3:0]             id;
        bit [31:0]            addr;
        bit [7:0]             burst_len;      // AxLEN (0 = 1 beat, 255 = 256 beats)
        axi_burst_e           burst_type;     // FIXED, INCR, WRAP
        bit [2:0]             transfer_size;  // AxSIZE (2'b010 = 4 bytes)
        bit [31:0]            data[];         // Multi-beat data array
        bit [3:0]             wstrb[];        // Multi-beat strobe array
        axi_resp_e            resp_code;      // Target response (for slave)
        int unsigned          delay_cycles;   // Wait cycles before asserting handshake
        bit                   inject_error;   // Flag to force an error condition
    } axi_bfm_command;

    // Event captured by BFM upon handshake and pushed to Monitor
    typedef struct {
        axi_channel_e         channel_id;
        time                  timestamp;
        longint               cycle_count;
        bit                   valid;
        bit                   ready;
        bit [3:0]             id;
        bit [31:0]            addr;
        bit [7:0]             burst_len;
        bit [2:0]             transfer_size;
        axi_burst_e           burst_type;
        bit [3:0]             cache;
        bit [2:0]             prot;
        bit [31:0]            data;
        bit [3:0]             wstrb;
        bit                   last;
        axi_resp_e            resp;
    } axi_bfm_event;

    // User-side BFM Command structure
    typedef struct {
        bit [31:0]            start_addr;
        bit [31:0]            total_bytes;
        bit                   rnw;            // 0=Write, 1=Read
        bit [1:0]             burst;          // User burst type
        bit [31:0]            data_words[];   // User write payload words
        bit [3:0]             wstrb[];        // User write strobe per word
        int unsigned          cmd_delay;      // Delay before command valid
        int unsigned          data_delay[];   // Delay before each data valid
    } user_bfm_command;

    // User-side BFM Event structure
    typedef struct {
        time                  timestamp;
        longint               cycle_count;
        bit                   is_cmd;         // 1=command handshake, 0=data handshake
        bit                   is_rx;          // 1=RX read data, 0=TX write data
        bit [31:0]            addr;
        bit [31:0]            total_bytes;
        bit                   rnw;
        bit [1:0]             burst;
        bit [31:0]            data;
        bit [3:0]             wstrb;
        bit                   write_complete;
        bit                   write_error;
        bit                   read_error;
    } user_bfm_event;

    // ------------------------------------------------------------------------
    // Mailbox Handle Type Definitions
    // ------------------------------------------------------------------------
    typedef mailbox #(axi_bfm_command)  axi_cmd_mbx_t;
    typedef mailbox #(axi_bfm_event)    axi_ev_mbx_t;
    typedef mailbox #(user_bfm_command) user_cmd_mbx_t;
    typedef mailbox #(user_bfm_event)   user_ev_mbx_t;

    // ------------------------------------------------------------------------
    // Utility Helper Functions for AXI4 Arithmetic
    // ------------------------------------------------------------------------

    // Returns bytes in a single beat from AxSIZE encoding
    function automatic int unsigned get_bytes_per_beat(bit [2:0] size);
        return (1 << size);
    endfunction

    // Computes aligned address by masking lower bits
    function automatic bit [31:0] get_aligned_addr(bit [31:0] addr, bit [2:0] size);
        bit [31:0] byte_lanes;
        byte_lanes = (1 << size) - 1;
        return (addr & ~byte_lanes);
    endfunction

    // Computes wrap boundary lower and upper limits
    function automatic void get_wrap_bounds(
        input  bit [31:0] start_addr,
        input  bit [7:0]  len,          // AxLEN: 1, 3, 7, or 15 for WRAP (2, 4, 8, 16 beats)
        input  bit [2:0]  size,
        output bit [31:0] wrap_lower,
        output bit [31:0] wrap_upper
    );
        int unsigned num_bytes;
        int unsigned total_wrap_bytes;
        num_bytes = 1 << size;
        total_wrap_bytes = (int'(len) + 1) * num_bytes;
        wrap_lower = (start_addr / total_wrap_bytes) * total_wrap_bytes;
        wrap_upper = wrap_lower + total_wrap_bytes;
    endfunction

    // Calculates next burst address based on burst type
    function automatic bit [31:0] get_next_beat_addr(
        input bit [31:0]   curr_addr,
        input bit [7:0]    len,
        input bit [2:0]    size,
        input axi_burst_e  burst_type,
        input bit [31:0]   wrap_lower,
        input bit [31:0]   wrap_upper
    );
        bit [31:0] next_addr;
        int unsigned num_bytes;
        num_bytes = 1 << size;

        case (burst_type)
            AXI_BURST_FIXED: begin
                next_addr = curr_addr;
            end
            AXI_BURST_INCR: begin
                next_addr = curr_addr + num_bytes;
            end
            AXI_BURST_WRAP: begin
                next_addr = curr_addr + num_bytes;
                if (next_addr >= wrap_upper) begin
                    next_addr = wrap_lower;
                end
            end
            default: begin
                next_addr = curr_addr + num_bytes;
            end
        endcase
        return next_addr;
    endfunction

    // Checks whether an AXI burst crosses a 4KB boundary
    function automatic bit is_4kb_cross(bit [31:0] start_addr, bit [7:0] len, bit [2:0] size);
        bit [31:0] aligned_start;
        bit [31:0] end_addr;
        int unsigned num_bytes;
        num_bytes = 1 << size;
        aligned_start = get_aligned_addr(start_addr, size);
        end_addr = aligned_start + ((int'(len) + 1) * num_bytes) - 1;
        return (start_addr[31:12] != end_addr[31:12]);
    endfunction

endpackage : axi_types_pkg

`endif // AXI_TYPES_PKG_SV
