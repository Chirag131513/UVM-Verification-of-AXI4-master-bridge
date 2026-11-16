// ============================================================================
// File: axi_base_vseq.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Base Virtual Sequence providing sequencer access and utility tasks
//              for issuing user writes, reads, and configuring slave responder behavior.
// ============================================================================

`ifndef AXI_BASE_VSEQ_SV
`define AXI_BASE_VSEQ_SV

class axi_base_vseq extends uvm_sequence;
    `uvm_object_utils(axi_base_vseq)
    `uvm_declare_p_sequencer(axi_virtual_sequencer)

    function new(string name = "axi_base_vseq");
        super.new(name);
    endfunction

    // ------------------------------------------------------------------------
    // Helper task: Send User Write Transaction
    // ------------------------------------------------------------------------
    task send_user_write(
        input bit [31:0] addr,
        input bit [31:0] total_bytes,
        input bit [1:0]  burst = 2'b01,
        input bit [31:0] data[] = null,
        input bit [3:0]  wstrb[] = null
    );
        user_transaction u_tx;
        u_tx = user_transaction::type_id::create("u_tx");
        
        start_item(u_tx, -1, p_sequencer.usr_sqr);
        u_tx.rnw         = 1'b0;
        u_tx.start_addr  = addr;
        u_tx.total_bytes = total_bytes;
        u_tx.burst       = burst;

        if (data != null && data.size() > 0) begin
            u_tx.tx_data = data;
        end else begin
            int n_words = (total_bytes + addr[1:0] + 3) / 4;
            u_tx.tx_data = new[n_words];
            for (int i = 0; i < n_words; i++) u_tx.tx_data[i] = $urandom();
        end

        if (wstrb != null && wstrb.size() > 0) begin
            u_tx.tx_wstrb = wstrb;
        end else begin
            int n_words = (total_bytes + addr[1:0] + 3) / 4;
            u_tx.tx_wstrb = new[n_words];
            for (int i = 0; i < n_words; i++) u_tx.tx_wstrb[i] = 4'b1111;
            // Mask first beat according to unaligned offset
            u_tx.tx_wstrb[0] = 4'b1111 << addr[1:0];
        end

        finish_item(u_tx);
    endtask

    // ------------------------------------------------------------------------
    // Helper task: Send User Read Transaction
    // ------------------------------------------------------------------------
    task send_user_read(
        input bit [31:0] addr,
        input bit [31:0] total_bytes,
        input bit [1:0]  burst = 2'b01
    );
        user_transaction u_tx;
        u_tx = user_transaction::type_id::create("u_tx");
        
        start_item(u_tx, -1, p_sequencer.usr_sqr);
        u_tx.rnw         = 1'b1;
        u_tx.start_addr  = addr;
        u_tx.total_bytes = total_bytes;
        u_tx.burst       = burst;
        finish_item(u_tx);
    endtask

endclass : axi_base_vseq

`endif // AXI_BASE_VSEQ_SV
