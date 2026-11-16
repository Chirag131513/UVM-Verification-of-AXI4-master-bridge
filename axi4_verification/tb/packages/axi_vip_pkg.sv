// ============================================================================
// File: axi_vip_pkg.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Primary VIP package assembling all transactions, agents,
//              models, scoreboards, coverage models, sequences, and tests.
// ============================================================================

`ifndef AXI_VIP_PKG_SV
`define AXI_VIP_PKG_SV

`include "uvm_macros.svh"

package axi_vip_pkg;

    import uvm_pkg::*;
    import axi_types_pkg::*;

    // 1. Transactions
    `include "axi_transaction.sv"
    `include "user_transaction.sv"

    // 2. Agent Configurations
    `include "axi_agent_configs.sv"

    // 3. Sequencers
    `include "axi_master_sequencer.sv"
    `include "axi_slave_sequencer.sv"
    `include "user_sequencer.sv"

    // 4. Drivers
    `include "axi_master_driver.sv"
    `include "axi_slave_driver.sv"
    `include "user_driver.sv"

    // 5. Independent Channel Monitors
    `include "axi_master_monitor.sv"
    `include "axi_slave_monitor.sv"
    `include "user_monitor.sv"

    // 6. Agents
    `include "axi_master_agent.sv"
    `include "axi_slave_agent.sv"
    `include "user_agent.sv"

    // 7. Reference Models
    `include "axi_reference_memory.sv"
    `include "axi_burst_predictor.sv"

    // 8. Scoreboards
    `include "axi_protocol_scoreboard.sv"
    `include "axi_memory_scoreboard.sv"
    `include "axi_scoreboard.sv"

    // 9. Functional Coverage & Performance Monitor
    `include "axi_functional_coverage.sv"
    `include "axi_performance_monitor.sv"

    // 10. Virtual Sequencer & Sequences
    `include "axi_virtual_sequencer.sv"
    `include "axi_base_vseq.sv"
    `include "axi_virtual_sequences.sv"

    // 11. Environment
    `include "axi_env_config.sv"
    `include "axi_env.sv"

    // 12. Tests
    `include "axi_base_test.sv"
    `include "axi_directed_test.sv"
    `include "axi_random_test.sv"
    `include "axi_stress_test.sv"

endpackage : axi_vip_pkg

`endif // AXI_VIP_PKG_SV
