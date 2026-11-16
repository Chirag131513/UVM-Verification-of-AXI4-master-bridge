// ============================================================================
// File: axi_reference_memory.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Byte-accurate Reference Memory Model with sparse associative storage,
//              byte-strobe masking, and independent data bus lane mapping.
// ============================================================================

`ifndef AXI_REFERENCE_MEMORY_SV
`define AXI_REFERENCE_MEMORY_SV

class axi_reference_memory extends uvm_object;
    `uvm_object_utils(axi_reference_memory)

    // Sparse associative array: address -> byte
    protected bit [7:0] mem [bit [31:0]];

    function new(string name = "axi_reference_memory");
        super.new(name);
    endfunction

    // ------------------------------------------------------------------------
    // Write byte
    // ------------------------------------------------------------------------
    function void write_byte(bit [31:0] addr, bit [7:0] val);
        mem[addr] = val;
    endfunction

    // ------------------------------------------------------------------------
    // Read byte (defaults to 0x00 if unwritten)
    // ------------------------------------------------------------------------
    function bit [7:0] read_byte(bit [31:0] addr);
        if (mem.exists(addr)) return mem[addr];
        else                  return 8'h00;
    endfunction

    // ------------------------------------------------------------------------
    // Write 32-bit word with 4-bit byte strobe mapping
    // ------------------------------------------------------------------------
    function void write_word_with_strobes(bit [31:0] word_addr, bit [31:0] data, bit [3:0] wstrb);
        bit [31:0] base_addr;
        base_addr = {word_addr[31:2], 2'b00};
        for (int i = 0; i < 4; i++) begin
            if (wstrb[i]) begin
                mem[base_addr + i] = data[(i*8) +: 8];
            end
        end
    endfunction

    // ------------------------------------------------------------------------
    // Read 32-bit word
    // ------------------------------------------------------------------------
    function bit [31:0] read_word(bit [31:0] word_addr);
        bit [31:0] base_addr;
        bit [31:0] word_val = 32'h0;
        base_addr = {word_addr[31:2], 2'b00};
        for (int i = 0; i < 4; i++) begin
            word_val[(i*8) +: 8] = read_byte(base_addr + i);
        end
        return word_val;
    endfunction

    // ------------------------------------------------------------------------
    // Check if address has been initialized
    // ------------------------------------------------------------------------
    function bit exists(bit [31:0] addr);
        return mem.exists(addr);
    endfunction

    // ------------------------------------------------------------------------
    // Clear all memory
    // ------------------------------------------------------------------------
    function void clear();
        mem.delete();
    endfunction

endclass : axi_reference_memory

`endif // AXI_REFERENCE_MEMORY_SV
