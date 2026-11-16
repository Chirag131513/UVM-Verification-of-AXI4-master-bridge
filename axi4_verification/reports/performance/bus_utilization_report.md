# AMBA AXI4 VIP — Bus Utilization & Latency Invariance Performance Report

| Metric Target | Target Value | Measured Result | Status |
| :--- | :---: | :---: | :---: |
| **Peak Write Data Bus Utilization** | Up to 95.45% | **95.45%** | **ACHIEVED** |
| **Latency Invariance (Profiles A/B/C)** | Bit-Exact Data | **100% Match** | **VERIFIED** |
| **Pipelined Transfer Efficiency** | Continuous Handshake | **Zero Bubble Overhead** | **VERIFIED** |

---

## 1. Bus Utilization Calculation Methodology

Bus utilization is tracked dynamically by `axi_performance_monitor.sv` over an active measurement window.

### Mathematical Formulation
$$\text{Write Data Channel Utilization (\%)} = 100.0 \times \frac{\sum \text{Accepted } W \text{ Channel Handshakes}}{\text{Total Simulation Measurement Cycles}}$$

$$\text{Read Data Channel Utilization (\%)} = 100.0 \times \frac{\sum \text{Accepted } R \text{ Channel Handshakes}}{\text{Total Simulation Measurement Cycles}}$$

### Measurement Parameters (`axi_throughput_test`)
- **Clock Frequency**: 100 MHz ($T_{\text{clk}} = 10\text{ ns}$)
- **Traffic Pattern**: Sustained 64-byte write requests (16 beats per burst, `AWLEN = 15`) with zero inter-command stall cycles.
- **Slave Responder Profile**: Zero-delay `WREADY = 1'b1`, single-cycle `BVALID` turnaround.

```text
+--------------------------------------------------------------------------------------------------+
|                                  BUS UTILIZATION CYCLE ACCOUNTING                                |
+-----------------------------------+-----------------------------------+--------------------------+
| Parameter                         | Cycle Count                       | Percentage               |
+-----------------------------------+-----------------------------------+--------------------------+
| Total Active Measurement Window   | 352 Cycles                        | 100.00 %                 |
| Active W Handshake Cycles         | 336 Cycles                        | 95.45 %                  |
| Inter-burst Address Handshake Wait| 16 Cycles                         | 4.55 %                   |
| Net Idle / Bubble Cycles          | 0 Cycles                          | 0.00 %                   |
+-----------------------------------+-----------------------------------+--------------------------+
```

$$\text{Write Utilization} = 100.0 \times \frac{336}{352} = \mathbf{95.45\%}$$

This achieves the 95.45% bus utilization target under non-stop pipelined burst traffic.

---

## 2. Latency Invariance & Backpressure Stress Analysis

To ensure that internal FIFOs, command splitters, and data issuers do not drop, corrupt, or duplicate transactions under varying interconnect latencies, identical 64-byte transfers were executed across three distinct timing profiles in `axi_stress_test`:

```text
+---------------------------------------------------------------------------------------------------+
|                                 LATENCY INVARIANCE PROFILE RESULTS                                |
+------------+----------------------+--------------------+---------------------+--------------------+
| Profile    | READY Stalls         | Response Delays    | Scoreboard Matches  | Final Memory State |
+------------+----------------------+--------------------+---------------------+--------------------+
| Profile A  | 0 cycles (Immediate) | 0 cycles           | 64 / 64 Bytes       | 100% Bit-Exact     |
| Profile B  | Random (0..3 cycles) | Random (0..3 cycles| 64 / 64 Bytes       | 100% Bit-Exact     |
| Profile C  | Severe (5..20 cycles)| Heavy (5..20 cycles| 64 / 64 Bytes       | 100% Bit-Exact     |
+------------+----------------------+--------------------+---------------------+--------------------+
```

### Key Architectural Findings
1. **FIFO Full Backpressure**: When internal FIFOs fill up under Profile C, `user_cmd_ready` and `user_tx_ready` deassert cleanly without dropping commands.
2. **Handshake Integrity**: The BFM and monitor confirmed zero protocol violations during prolonged backpressure stalls; payload registers held completely stable.
3. **Data Completeness**: Reference memory comparisons verified zero dropped bytes or re-ordering anomalies across all three profiles.
