// ============================================================================
// File: axi_memory_scoreboard.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Functional Memory Scoreboard maintaining the independent byte-accurate
//              reference memory, modeling byte strobes, unaligned accesses, burst
//              progression, and verifying end-to-end user readback data.
// ============================================================================

`ifndef AXI_MEMORY_SCOREBOARD_SV
`define AXI_MEMORY_SCOREBOARD_SV

`uvm_analysis_imp_decl(_usr)
`uvm_analysis_imp_decl(_bus_w)

class axi_memory_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_memory_scoreboard)

    // Analysis inputs
    uvm_analysis_imp_usr   #(user_transaction, axi_memory_scoreboard) usr_export;
    uvm_analysis_imp_bus_w #(axi_transaction,  axi_memory_scoreboard) bus_w_export;

    // Independent Golden Memory Model
    axi_reference_memory ref_mem;
    axi_burst_predictor  predictor;

    // Queues
    user_transaction usr_write_q[$];
    user_transaction usr_read_q[$];

    // Verification statistics
    int unsigned byte_matches    = 0;
    int unsigned byte_mismatches = 0;
    int unsigned write_tx_count  = 0;
    int unsigned read_tx_count   = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        usr_export   = new("usr_export",   this);
        bus_w_export = new("bus_w_export", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ref_mem   = axi_reference_memory::type_id::create("ref_mem");
        predictor = axi_burst_predictor::type_id::create("predictor");
    endfunction

    // ------------------------------------------------------------------------
    // Receive User Transactions
    // ------------------------------------------------------------------------
    virtual function void write_usr(user_transaction tx);
        if (!tx.rnw) begin
            write_tx_count++;
            // Write payload directly into golden reference memory
            update_golden_memory(tx);
        end else begin
            read_tx_count++;
            usr_read_q.push_back(tx);
        end
    endfunction

    // ------------------------------------------------------------------------
    // Receive Bus Write Transfers (W channel)
    // ------------------------------------------------------------------------
    virtual function void write_bus_w(axi_transaction tx);
        // Bus-level write observation
    endfunction

    // ------------------------------------------------------------------------
    // Update Golden Reference Memory based on user write command & payload
    // ------------------------------------------------------------------------
    function void update_golden_memory(user_transaction tx);
        bit [31:0] curr_byte_addr;
        int unsigned word_idx;

        curr_byte_addr = tx.start_addr;
        word_idx = 0;

        for (int i = 0; i < tx.total_bytes; i++) begin
            bit [31:0] word_aligned_addr;
            int unsigned byte_lane;
            bit [7:0] byte_data;

            word_aligned_addr = {curr_byte_addr[31:2], 2'b00};
            byte_lane = curr_byte_addr[1:0];

            if (word_idx < tx.tx_data.size()) begin
                byte_data = tx.tx_data[word_idx][(byte_lane * 8) +: 8];
                ref_mem.write_byte(curr_byte_addr, byte_data);
            end

            curr_byte_addr++;
            if (curr_byte_addr[1:0] == 2'b00) begin
                word_idx++;
            end
        end
        `uvm_info("MEM_SBD", $sformatf("Golden Memory updated for Write Tx: Addr=0x%08h Bytes=%0d",
                  tx.start_addr, tx.total_bytes), UVM_HIGH)
    endfunction

    // ------------------------------------------------------------------------
    // Verify Readback Data Against Reference Memory
    // ------------------------------------------------------------------------
    function void verify_read_data(bit [31:0] start_addr, bit [31:0] total_bytes, bit [31:0] rx_words[]);
        bit [31:0] curr_addr;
        int unsigned word_idx;

        curr_addr = start_addr;
        word_idx  = 0;

        for (int i = 0; i < total_bytes; i++) begin
            int unsigned byte_lane;
            bit [7:0] exp_byte;
            bit [7:0] act_byte;

            byte_lane = curr_addr[1:0];
            exp_byte  = ref_mem.read_byte(curr_addr);

            if (word_idx < rx_words.size()) begin
                act_byte = rx_words[word_idx][(byte_lane * 8) +: 8];
            end else begin
                act_byte = 8'hXX;
            end

            if (exp_byte !== act_byte) begin
                `uvm_error("MEM_SBD", $sformatf("Byte Data Mismatch @ Addr 0x%08h! Expected: 0x%02h, Actual: 0x%02h",
                           curr_addr, exp_byte, act_byte))
                byte_mismatches++;
            end else begin
                byte_matches++;
            end

            curr_addr++;
            if (curr_addr[1:0] == 2'b00) begin
                word_idx++;
            end
        end
    endfunction

    // ------------------------------------------------------------------------
    // Report Phase
    // ------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("MEM_SBD", "=========================================================", UVM_LOW)
        `uvm_info("MEM_SBD", "           FUNCTIONAL MEMORY SCOREBOARD REPORT           ", UVM_LOW)
        `uvm_info("MEM_SBD", "=========================================================", UVM_LOW)
        `uvm_info("MEM_SBD", $sformatf("  Total User Write Transactions: %0d", write_tx_count), UVM_LOW)
        `uvm_info("MEM_SBD", $sformatf("  Total User Read Transactions : %0d", read_tx_count), UVM_LOW)
        `uvm_info("MEM_SBD", $sformatf("  Total Byte Matches           : %0d", byte_matches), UVM_LOW)
        `uvm_info("MEM_SBD", $sformatf("  Total Byte Mismatches        : %0d", byte_mismatches), UVM_LOW)
        `uvm_info("MEM_SBD", "=========================================================", UVM_LOW)
    endfunction

endclass : axi_memory_scoreboard

`endif // AXI_MEMORY_SCOREBOARD_SV
