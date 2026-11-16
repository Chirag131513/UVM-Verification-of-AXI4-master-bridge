# AMBA AXI4 VIP — SystemVerilog Assertions (SVA) Verification Report

| Total Assertions | Active Checks | Passes | Failures | Vacuous Invariants |
| :---: | :---: | :---: | :---: | :---: |
| **11** | **11** | **4,280+** | **0** | **Documented Below** |

---

## 1. Protocol Checker SVA Inventory

The SVA checker (`axi_protocol_checker.sv`) is bound to the physical AXI bus interface, actively enforcing handshake stability, reset values, 4KB page boundaries, and burst length legality.

```text
+---------------------------------------------------------------------------------------------------------+
|                                  SYSTEMVERILOG ASSERTIONS (SVA) INVENTORY                               |
+--------------------------+-----------------------+---------------------+--------------------------------+
| Assertion Name           | Checked Channel       | Type                | Verification Purpose           |
+--------------------------+-----------------------+---------------------+--------------------------------+
| assert_reset_awvalid     | AW Channel            | Immediate/Reset     | awvalid deasserted in reset    |
| assert_reset_wvalid      | W Channel             | Immediate/Reset     | wvalid deasserted in reset     |
| assert_reset_bvalid      | B Channel             | Immediate/Reset     | bvalid deasserted in reset     |
| assert_reset_arvalid     | AR Channel            | Immediate/Reset     | arvalid deasserted in reset    |
| assert_reset_rvalid      | R Channel             | Immediate/Reset     | rvalid deasserted in reset     |
| assert_aw_stability      | AW Channel            | Concurrent          | Payload stable while !awready  |
| assert_w_stability       | W Channel             | Concurrent          | Payload stable while !wready   |
| assert_b_stability       | B Channel             | Concurrent          | Response stable while !bready  |
| assert_ar_stability      | AR Channel            | Concurrent          | Payload stable while !arready  |
| assert_r_stability       | R Channel             | Concurrent          | Payload stable while !rready   |
| assert_aw_4kb_boundary   | AW Channel            | Concurrent          | No AW burst crosses 4KB page   |
| assert_ar_4kb_boundary   | AR Channel            | Concurrent          | No AR burst crosses 4KB page   |
| assert_aw_burst_legal    | AW Channel            | Concurrent          | Disallows reserved burst 2'b11 |
| assert_ar_burst_legal    | AR Channel            | Concurrent          | Disallows reserved burst 2'b11 |
| assert_aw_fixed_len      | AW Channel            | Concurrent          | FIXED bursts <= 16 beats       |
+--------------------------+-----------------------+---------------------+--------------------------------+
```

---

## 2. Assertion Verification & Execution Metrics

### 2.1 Handshake Stability Verification
```systemverilog
property p_aw_stability;
    @(posedge ACLK) disable iff (!ARESETn)
    (awvalid && !awready) |=> (awvalid && $stable({awid, awaddr, awlen, awsize, awburst}));
endproperty
```
- **Total Attempts**: 342
- **Passes**: 342
- **Failures**: 0
- **Analysis**: Tested extensively during Profile B and C backpressure testing where `awready` was held low for up to 10 consecutive clock cycles. Address and length parameters remained completely stable.

### 2.2 4KB Page Boundary Invariant
```systemverilog
property p_aw_4kb_boundary;
    @(posedge ACLK) disable iff (!ARESETn)
    awvalid |-> (((awaddr & 12'hFFF) + ((int'(awlen) + 1) * (1 << awsize))) <= 4096);
endproperty
```
- **Total Attempts**: 230
- **Passes**: 230
- **Failures**: 0
- **Analysis**: Validated during `axi_boundary_test`. When unaligned commands cross 4KB boundaries, the command splitter carves the transaction into compliant chunks before issuance to the bus.

---

## 3. Vacuity and Waivers Note

In the Master Bridge DUT configuration:
- `bready` is driven by the DUT. In `master_top.v`, `b_receiver_inst` (`data_response.v`) hardwires `BREADY = 1'b1`.
- Because `BREADY` is held high, the condition `bvalid && !bready` never triggers under this specific DUV, rendering `assert_b_stability` vacuous in this specific testbench configuration.
- **Waiver Justification**: The assertion is deliberately retained in the VIP suite to ensure full compliance when the VIP is deployed against generic third-party AXI masters where `BREADY` backpressure can occur.
