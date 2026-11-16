# AXI4 Master Bridge — Hardware Defect & Errata Report

| Document ID | DUV Target | Verification Methodology | Status | Date |
| :--- | :--- | :--- | :--- | :--- |
| **DEF-AXI4-2026-R01** | `master_top` (AXI4 Master Bridge) | UVM 1.2 Multi-Channel VIP | **CONFIRMED** | 2026-11-16 |

---

## 1. Executive Summary

During the execution of the advanced UVM Verification IP (VIP) test suite on the unmodified **AXI4 Master Bridge RTL**, **eight (8) microarchitectural defects** were identified. 

In strict adherence to the project specification (*"Do not modify the DUT RTL to make verification pass... Identify DUT bugs separately from testbench bugs"*), the hardware under test was preserved in its pristine state, and each bug has been isolated, documented with cycle-accurate timing traces, and categorized below.

```
+--------------------------------------------------------------------------------------------------------+
|                                  DEFECT SEVERITY & MODULE DISTRIBUTION                                 |
+-------------------+----------------------+--------------------+----------------------------------------+
| Defect ID         | Target Module        | Severity           | Protocol Invariant Affected            |
+-------------------+----------------------+--------------------+----------------------------------------+
| DUT-BUG-01        | addr_issuer.v        | Critical           | Reset Address & Length Issuance        |
| DUT-BUG-02        | data_issuer.v        | Major              | Single-Beat WLAST Assertion            |
| DUT-BUG-03        | data_issuer.v        | Critical           | Initial Beat Data Corruption           |
| DUT-BUG-04        | data_issuer.v        | Major              | Multi-Beat Command FIFO Popping        |
| DUT-BUG-05        | data_issuer.v        | Critical           | Payload-Dependent Beat Counter Reset   |
| DUT-BUG-06        | master_top.v         | Major              | RX FIFO Bypass & Data Loss             |
| DUT-BUG-07        | sync_fifo.v          | Compliance         | Continuous Assign to Output Reg        |
| DUT-BUG-08        | addr_splitter.v      | Minor              | Start Offset Propagation in Multi-Burst|
+-------------------+----------------------+--------------------+----------------------------------------+
```

---

## 2. Detailed Hardware Defect Catalog

### 2.1 DUT-BUG-01: Zero Address & Length Issuance on Startup
- **Module**: `addr_issuer.v` (Lines 139–151)
- **Severity**: **Critical**
- **Trigger Test**: `axi_directed_test` / `axi_basic_vseq`
- **AXI4 Spec Reference**: Section A3.1.1 (Address Channel Valid and Ready Handshakes)

#### Root Cause Analysis
In `addr_issuer.v`, `AXVALID` is tied directly to `!fifo_empty`. However, `AXADDR` and `AXLEN` are registered variables that are initialized to `0` upon reset and are only updated when an internal register `start` is set:
```verilog
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        AXADDR <= 0;
        AXLEN  <= 0;
    end
    else if (ax_handshake) begin
        start = 1'b1;
    end
    else if (start) begin
        AXADDR = cmd_addr;
        AXLEN  = cmd_axi_len;
    end
end
```
When the first command enters the FIFO after reset, `fifo_empty` drops to `0`, immediately driving `AXVALID = 1`. Because `ax_handshake` has not yet occurred, `start` is `0`, causing `AXADDR` to drive `32'h0000_0000` and `AXLEN` to drive `8'h00`. The slave accepts address 0 and length 0 regardless of the user's commanded address.

#### Cycle Timing Trace
```text
Clock Cycle :    1        2        3        4        5
ARESETn     : ___/------------------------------------
fifo_empty  : -----------X_______
cmd_addr    : -----------X 0x1000
AXVALID     : ___________/----------------------------
AXADDR (Act): 0x00000000 0x00000000 0x00000000 (ERROR: 0x0 driven!)
AXADDR (Exp): 0x00000000 0x00001000 0x00001000
AXREADY     : ___________________/--------------------  <-- Handshake on Cycle 4
start       : ____________________________/-----------  <-- start sets AFTER handshake!
```

#### Recommended Fix
Directly assign `AXADDR` and `AXLEN` combinationally from `cmd_addr` and `cmd_axi_len` (as originally drafted in the commented lines 130–132):
```verilog
assign AXADDR = cmd_addr;
assign AXLEN  = cmd_axi_len;
```

---

### 2.2 DUT-BUG-02: Missing WLAST on Single-Beat Write Bursts
- **Module**: `data_issuer.v` (Line 35)
- **Severity**: **Major**
- **Trigger Test**: `axi_single_beat_test`
- **AXI4 Spec Reference**: Section A3.4.4 (Write Strobe and WLAST Signals)

#### Root Cause Analysis
`WLAST` is defined with an explicit condition that excludes single-beat transfers (`cmd_axi_len == 0`):
```verilog
assign WLAST = ((beat_counter == cmd_axi_len) && (cmd_axi_len != 0)) ? 1'b1 : 1'b0;
```
For a single-beat transfer (`AWLEN = 0`), `cmd_axi_len` is `0`. The term `(cmd_axi_len != 0)` evaluates to `1'b0`, forcing `WLAST` low throughout the burst. The AXI4 protocol mandates that single-beat transfers must assert `WLAST = 1` on their single data beat.

#### Cycle Timing Trace
```text
Clock Cycle :    1        2        3
WVALID      : ___________/--------
WREADY      : ___________/--------
beat_counter: 00000000   00000000
cmd_axi_len : 00000000   00000000
WLAST (Act) : 00000000   00000000  (ERROR: WLAST held at 0!)
WLAST (Exp) : 00000000   11111111  (Expected high on beat 0)
```

#### Recommended Fix
Remove the `cmd_axi_len != 0` exclusion:
```verilog
assign WLAST = (beat_counter == cmd_axi_len);
```

---

### 2.3 DUT-BUG-03: First Write Beat Data Forced to Zero
- **Module**: `data_issuer.v` (Line 28)
- **Severity**: **Critical**
- **Trigger Test**: `axi_directed_test` / `axi_basic_vseq`
- **AXI4 Spec Reference**: Section A3.4.1 (Write Data Channel Requirements)

#### Root Cause Analysis
`WDATA` is gated by the internal `start` register:
```verilog
assign WDATA = start ? tx_data : {DATA_WIDTH{1'b0}};
```
`start` is initialized to `0` upon reset and is only set to `1` inside `always @(posedge clk)` on the first `w_handshake`. Consequently, on the first beat of the first write transaction, `WDATA` is driven as `32'h0000_0000`, silently zeroing out the user's initial payload word.

#### Recommended Fix
Connect `WDATA` directly to `tx_data`:
```verilog
assign WDATA = tx_data;
```

---

### 2.4 DUT-BUG-04: Multi-Beat Command FIFO Popped on Every Data Beat
- **Module**: `data_issuer.v` (Line 37)
- **Severity**: **Major**
- **Trigger Test**: `axi_directed_test` (4-beat and 16-beat bursts)
- **AXI4 Spec Reference**: Section A3.4 (Data Channel Synchronization)

#### Root Cause Analysis
The write command FIFO pop signal is defined as:
```verilog
assign fifo_cmd_pop = (w_handshake);
```
In a multi-beat transfer of $N$ beats, `w_handshake` pulses on every single accepted beat. As a result, `w_cmd_fifo` is popped after beat 0. On beats $1 \dots N-1$, `cmd_axi_len` and `cmd_offset` are pulled from either the *subsequent* command in the queue or read garbage from an empty FIFO, breaking burst tracking and premature strobe masks.

#### Recommended Fix
Pop `w_cmd_fifo` only on the final beat of the burst:
```verilog
assign fifo_cmd_pop = (w_handshake && WLAST);
```

---

### 2.5 DUT-BUG-05: Payload-Dependent Beat Counter Reset on Zero Data
- **Module**: `data_issuer.v` (Line 45)
- **Severity**: **Critical**
- **Trigger Test**: `axi_random_test` / `axi_directed_test`
- **AXI4 Spec Reference**: Section A3.4 (Burst Length and Beat Counting)

#### Root Cause Analysis
The beat counter reset condition checks the data payload itself:
```verilog
if (w_handshake) begin
    start <= 1'b1;
    if (WLAST || WDATA == 0) begin
        beat_counter <= 8'd0; 
    end else begin
        beat_counter <= beat_counter + 1'b1;
    end
end
```
If an application transmits valid data containing `32'h0000_0000` (e.g., zeroed buffers, sparse matrices, or cleared headers), the hardware treats `WDATA == 0` as a burst completion, resetting `beat_counter` back to 0 in the middle of a burst and deadlocking or extending the transaction indefinitely.

#### Recommended Fix
Eliminate the data dependency:
```verilog
if (WLAST) begin
    beat_counter <= 8'd0;
end else begin
    beat_counter <= beat_counter + 1'b1;
end
```

---

### 2.6 DUT-BUG-06: RX FIFO Storage Bypassed on User Readback
- **Module**: `master_top.v` (Lines 307 & 311)
- **Severity**: **Major**
- **Trigger Test**: `axi_directed_test` / `axi_basic_vseq`
- **AXI4 Spec Reference**: Section A3.4.2 (Read Data Channel Buffering)

#### Root Cause Analysis
In `master_top.v`, `rx_data_fifo` is instantiated with its output port left unconnected:
```verilog
sync_fifo #(
    .DATA_WIDTH (DATA_WIDTH),
    .DEPTH      (FIFO_DEPTH)
) rx_data_fifo (
    .clk      (clk),
    .rst_n    (rst_n),
    .write_en (rx_data_wr_en),
    .read_en  (user_rx_ready),
    .data_in  (rx_data_in),
    .data_out (),             // <-- UNCONNECTED!
    .full     (rx_data_full),
    .empty    (rx_data_empty)
);
assign user_rx_data = rx_data_in;
```
`user_rx_data` is tied directly to `rx_data_in` (the wire carrying `m_axi_rdata`), completely bypassing the FIFO. If the user delays reading received data (`user_rx_ready == 0`), the bus moves on, and `user_rx_data` returns whatever transient state is currently on the bus rather than the buffered word.

#### Recommended Fix
Connect `rx_data_fifo`'s `data_out` to an internal wire and assign it to `user_rx_data`:
```verilog
wire [DATA_WIDTH-1:0] rx_data_out;
...
    .data_out (rx_data_out)
...
assign user_rx_data = rx_data_out;
```

---

### 2.7 DUT-BUG-07: Continuous Assignment to Output Reg in FIFO
- **Module**: `sync_fifo.v` (Lines 10 & 52)
- **Severity**: **Compliance**
- **Trigger Test**: Elaboration / Linting with strict Verilog tools (Icarus, Genus, Design Compiler)

#### Root Cause Analysis
In `sync_fifo.v`, `data_out` is declared as:
```verilog
output reg [DATA_WIDTH-1:0] data_out,
```
and then assigned via:
```verilog
assign data_out = mem[rd_ptr];
```
In IEEE 1364-2001 Verilog, a `reg` cannot be driven by continuous assignment. Strict compilers issue compile-time fatal errors.

#### Recommended Fix
Change `output reg` to `output wire`:
```verilog
output wire [DATA_WIDTH-1:0] data_out,
```

---

### 2.8 DUT-BUG-08: Persistent Byte Offset in Split Bursts
- **Module**: `addr_splitter.v` (Line 89)
- **Severity**: **Minor**
- **Trigger Test**: `axi_boundary_test`
- **AXI4 Spec Reference**: Section A3.4.1 (Unaligned Burst Splitting)

#### Root Cause Analysis
When an unaligned user request crosses a 4KB page boundary, it is split into two or more AXI bursts. The first burst begins at `start_addr` (with unaligned offset `start_offset`). Subsequent bursts, however, begin on a 4KB boundary and are strictly word-aligned. In `SPLIT` state:
```verilog
cmd_offset <= start_offset_reg;
```
`cmd_offset` receives `start_offset_reg` for *all* sub-bursts, causing the W-issuer to incorrectly apply starting strobe masks on the first beat of subsequent bursts.

#### Recommended Fix
Clear `cmd_offset` for bursts after the initial split:
```verilog
cmd_offset <= (rem_bytes == full_bytes) ? start_offset_reg : 3'b000;
```

---

## 3. Summary of Verification Handling

The advanced UVM Verification IP framework is designed to detect, log, and isolate all eight defects without masking them or causing testbench deadlocks:
1. The **Protocol Scoreboard** detects missing `WLAST` assertions and premature command popping.
2. The **Functional Memory Scoreboard** detects data corruption, byte lane mapping mismatches, and RX bypass loss.
3. The **SVA Protocol Checker** flags bus instability and page boundary crossings.
4. The **Defect Reproduction Tests** provided in `axi_directed_test.sv` provide single-click isolation for every item in this report.
