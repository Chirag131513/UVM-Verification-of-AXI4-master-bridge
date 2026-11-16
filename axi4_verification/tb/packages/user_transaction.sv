// ============================================================================
// File: user_transaction.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: User-side transaction class modeling application-level byte transfers,
//              unaligned addresses, burst lengths, and payload streams.
// ============================================================================

`ifndef USER_TRANSACTION_SV
`define USER_TRANSACTION_SV

class user_transaction extends uvm_sequence_item;

    // ------------------------------------------------------------------------
    // User Command Parameters
    // ------------------------------------------------------------------------
    rand bit [31:0]             start_addr;
    rand bit [31:0]             total_bytes;
    rand bit                    rnw;           // 0 = Write, 1 = Read
    rand bit [1:0]              burst;         // 00=FIXED, 01=INCR, 10=WRAP

    // ------------------------------------------------------------------------
    // Write Data Stream (Payload and Strobes)
    // ------------------------------------------------------------------------
    rand bit [31:0]             tx_data[];
    rand bit [3:0]              tx_wstrb[];

    // ------------------------------------------------------------------------
    // Read Data Stream (Captured from DUT)
    // ------------------------------------------------------------------------
    bit [31:0]                  rx_data[];

    // ------------------------------------------------------------------------
    // DUT Status Flags
    // ------------------------------------------------------------------------
    bit                         write_complete;
    bit                         write_error;
    bit                         read_error;

    // ------------------------------------------------------------------------
    // Delays
    // ------------------------------------------------------------------------
    rand int unsigned           cmd_delay;
    rand int unsigned           tx_delay[];

    // ------------------------------------------------------------------------
    // UVM Utilities
    // ------------------------------------------------------------------------
    `uvm_object_utils_begin(user_transaction)
        `uvm_field_int(start_addr,                 UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(total_bytes,                UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(rnw,                        UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(burst,                      UVM_ALL_ON | UVM_BIN)
        `uvm_field_array_int(tx_data,              UVM_ALL_ON | UVM_HEX)
        `uvm_field_array_int(tx_wstrb,             UVM_ALL_ON | UVM_BIN)
        `uvm_field_array_int(rx_data,              UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(write_complete,             UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(write_error,                UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(read_error,                 UVM_ALL_ON | UVM_BIN)
    `uvm_object_utils_end

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function new(string name = "user_transaction");
        super.new(name);
        cmd_delay = 0;
        burst     = 2'b01; // Default INCR
    endfunction

    // ------------------------------------------------------------------------
    // Constraints
    // ------------------------------------------------------------------------
    constraint c_transfer_bounds {
        total_bytes inside {[1 : 256]};
        cmd_delay inside {[0 : 5]};
    }

    // Dynamic sizing of write payloads
    constraint c_tx_payload {
        if (!rnw) {
            tx_data.size()  == (total_bytes + (start_addr[1:0]) + 3) / 4;
            tx_wstrb.size() == tx_data.size();
            tx_delay.size() == tx_data.size();
            foreach (tx_delay[i]) tx_delay[i] inside {[0:4]};
            foreach (tx_wstrb[i]) tx_wstrb[i] inside {[4'b0001 : 4'b1111]};
        } else {
            tx_data.size()  == 0;
            tx_wstrb.size() == 0;
            tx_delay.size() == 0;
        }
    }

    // ------------------------------------------------------------------------
    // Helper: compute expected words count
    // ------------------------------------------------------------------------
    function int unsigned get_word_count();
        return (total_bytes + start_addr[1:0] + 3) / 4;
    endfunction

    // ------------------------------------------------------------------------
    // String Conversion
    // ------------------------------------------------------------------------
    virtual function string convert2string();
        string s;
        s = $sformatf("USER_TX: Op=%s Addr=0x%08h Bytes=%0d Burst=2'b%02b Words=%0d Status=[WComp=%0b WErr=%0b RErr=%0b]",
                      rnw ? "READ" : "WRITE", start_addr, total_bytes, burst, tx_data.size(),
                      write_complete, write_error, read_error);
        return s;
    endfunction

endclass : user_transaction

`endif // USER_TRANSACTION_SV
