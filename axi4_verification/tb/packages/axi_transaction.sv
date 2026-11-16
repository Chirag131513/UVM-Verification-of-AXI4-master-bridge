// ============================================================================
// File: axi_transaction.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Comprehensive AXI4 transaction class supporting burst lengths
//              up to 256 beats, dynamic payload sizing, and standard constraints.
// ============================================================================

`ifndef AXI_TRANSACTION_SV
`define AXI_TRANSACTION_SV

class axi_transaction extends uvm_sequence_item;

    // ------------------------------------------------------------------------
    // Channel Configuration & Addressing
    // ------------------------------------------------------------------------
    rand bit [3:0]              id;
    rand bit [31:0]             addr;
    rand bit [7:0]              len;           // 0 to 255 (1 to 256 beats)
    rand axi_size_e             size;          // 2'b010 (4 bytes) default
    rand axi_burst_e            burst;         // FIXED, INCR, WRAP
    rand bit [3:0]              cache;
    rand bit [2:0]              prot;
    rand axi_op_e               op_type;       // AXI_OP_WRITE or AXI_OP_READ

    // ------------------------------------------------------------------------
    // Payloads & Strobes (Sized to len + 1)
    // ------------------------------------------------------------------------
    rand bit [31:0]             data[];
    rand bit [3:0]              wstrb[];
    rand axi_resp_e             bresp;
    rand axi_resp_e             rresp[];
    bit                         wlast[];
    bit                         rlast[];

    // ------------------------------------------------------------------------
    // Reactive Timing & Latency Knobs (Profile A/B/C)
    // ------------------------------------------------------------------------
    rand int unsigned           ready_delay[]; // Delay before asserting READY per beat
    rand int unsigned           addr_ready_delay;
    rand int unsigned           resp_delay;    // Delay before BVALID or RVALID
    rand axi_timing_profile_e   timing_profile;

    // ------------------------------------------------------------------------
    // Transaction Metadata (Collected by Monitors)
    // ------------------------------------------------------------------------
    time                        start_time;
    time                        end_time;
    longint                     start_cycle;
    longint                     end_cycle;

    // ------------------------------------------------------------------------
    // UVM Utilities
    // ------------------------------------------------------------------------
    `uvm_object_utils_begin(axi_transaction)
        `uvm_field_int(id,                         UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(addr,                       UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(len,                        UVM_ALL_ON | UVM_DEC)
        `uvm_field_enum(axi_size_e, size,          UVM_ALL_ON)
        `uvm_field_enum(axi_burst_e, burst,        UVM_ALL_ON)
        `uvm_field_int(cache,                      UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(prot,                       UVM_ALL_ON | UVM_BIN)
        `uvm_field_enum(axi_op_e, op_type,         UVM_ALL_ON)
        `uvm_field_array_int(data,                 UVM_ALL_ON | UVM_HEX)
        `uvm_field_array_int(wstrb,                UVM_ALL_ON | UVM_BIN)
        `uvm_field_enum(axi_resp_e, bresp,         UVM_ALL_ON)
        `uvm_field_array_enum(axi_resp_e, rresp,   UVM_ALL_ON)
        `uvm_field_enum(axi_timing_profile_e, timing_profile, UVM_ALL_ON)
    `uvm_object_utils_end

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function new(string name = "axi_transaction");
        super.new(name);
        timing_profile   = PROFILE_LOW_LATENCY;
        addr_ready_delay = 0;
        resp_delay       = 0;
        size             = AXI_SIZE_4_BYTES;
        burst            = AXI_BURST_INCR;
        cache            = 4'b0011;
        prot             = 3'b000;
        bresp            = AXI_RESP_OKAY;
    endfunction

    // ------------------------------------------------------------------------
    // Constraints (AMBA AXI4 Compliant)
    // ------------------------------------------------------------------------
    
    // Dynamic array sizing constraint
    constraint c_payload_sizes {
        data.size()        == int'(len) + 1;
        wstrb.size()       == int'(len) + 1;
        rresp.size()       == int'(len) + 1;
        ready_delay.size() == int'(len) + 1;
    }

    // AXI4 Legal burst specifications
    constraint c_legal_axi4 {
        burst != AXI_BURST_RESERVED;
        size  <= AXI_SIZE_4_BYTES; // DUT data bus width is 32-bit (4 bytes)

        // FIXED burst limited to 16 beats
        if (burst == AXI_BURST_FIXED) {
            len <= 8'd15;
        }

        // WRAP burst must be 2, 4, 8, or 16 beats and address-aligned
        if (burst == AXI_BURST_WRAP) {
            len inside {8'd1, 8'd3, 8'd7, 8'd15};
            (addr & ((1 << size) - 1)) == 0;
        }

        // No burst may cross 4KB page boundary
        ((addr & 12'hFFF) + ((int'(len) + 1) * (1 << size))) <= 4096;
    }

    // Default strobe constraint: non-zero for active writes
    constraint c_default_strobes {
        foreach (wstrb[i]) {
            wstrb[i] inside {[4'b0001 : 4'b1111]};
        }
    }

    // Timing profile delay constraints
    constraint c_timing_delays {
        if (timing_profile == PROFILE_LOW_LATENCY) {
            addr_ready_delay == 0;
            resp_delay       == 0;
            foreach (ready_delay[i]) ready_delay[i] == 0;
        }
        else if (timing_profile == PROFILE_RANDOM_DELAY) {
            addr_ready_delay inside {[0:5]};
            resp_delay       inside {[0:5]};
            foreach (ready_delay[i]) ready_delay[i] inside {[0:5]};
        }
        else if (timing_profile == PROFILE_STRESS_STALL) {
            addr_ready_delay inside {[5:20]};
            resp_delay       inside {[5:20]};
            foreach (ready_delay[i]) ready_delay[i] inside {[5:20]};
        }
    }

    // ------------------------------------------------------------------------
    // Post Randomize: update last flags
    // ------------------------------------------------------------------------
    function void post_randomize();
        wlast = new[int'(len) + 1];
        rlast = new[int'(len) + 1];
        for (int i = 0; i <= int'(len); i++) {
            wlast[i] = (i == int'(len));
            rlast[i] = (i == int'(len));
        }
    endfunction

    // ------------------------------------------------------------------------
    // String Conversion for logging
    // ------------------------------------------------------------------------
    virtual function string convert2string();
        string s;
        s = $sformatf("AXI_TX: Op=%s ID=0x%0h Addr=0x%08h Len=%0d (%0d beats) Size=%0d Burst=%s BResp=%s",
                      op_type.name(), id, addr, len, len + 1, (1 << size), burst.name(), bresp.name());
        return s;
    endfunction

endclass : axi_transaction

`endif // AXI_TRANSACTION_SV
