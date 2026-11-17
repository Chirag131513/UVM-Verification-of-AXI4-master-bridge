// ============================================================================
// File: axi_master_monitor.sv
// Project: AMBA AXI4 Protocol Verification & VIP Environment
// Description: Multi-channel AXI4 Monitor hosting 5 strictly independent monitor
//              engines for AW, W, B, AR, and R channels, publishing solely on
//              VALID && READY handshakes through separate analysis ports.
// ============================================================================

`ifndef AXI_MASTER_MONITOR_SV
`define AXI_MASTER_MONITOR_SV

class axi_master_monitor extends uvm_monitor;
    `uvm_component_utils(axi_master_monitor)

    // Virtual interface handle to physical AXI bus
    virtual axi_interface.monitor_mp vif;
    axi_master_config cfg;

    // 5 Independent Analysis Ports for the 5 Channels
    uvm_analysis_port #(axi_transaction) aw_ap;
    uvm_analysis_port #(axi_transaction) w_ap;
    uvm_analysis_port #(axi_transaction) b_ap;
    uvm_analysis_port #(axi_transaction) ar_ap;
    uvm_analysis_port #(axi_transaction) r_ap;

    // Cycle tracker
    longint unsigned cycle_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        aw_ap = new("aw_ap", this);
        w_ap  = new("w_ap",  this);
        b_ap  = new("b_ap",  this);
        ar_ap = new("ar_ap", this);
        r_ap  = new("r_ap",  this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_interface.monitor_mp)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MST_MON", "virtual axi_interface.monitor_mp not found in config_db")
        end
        if (!uvm_config_db#(axi_master_config)::get(this, "", "cfg", cfg)) begin
            cfg = axi_master_config::type_id::create("cfg");
        end
    endfunction

    task run_phase(uvm_phase phase);
        wait(vif.ARESETn === 1'b1);
        fork
            cycle_counter();
            monitor_aw_channel();
            monitor_w_channel();
            monitor_b_channel();
            monitor_ar_channel();
            monitor_r_channel();
        join
    endtask

    task cycle_counter();
        forever begin
            @(vif.cb_mon);
            if (!vif.ARESETn) cycle_count = 0;
            else              cycle_count = cycle_count + 1;
        end
    endtask

    // ------------------------------------------------------------------------
    // Channel 1: AW Independent Monitor
    // ------------------------------------------------------------------------
    task monitor_aw_channel();
        forever begin
            @(vif.cb_mon);
            if (vif.ARESETn && vif.cb_mon.awvalid && vif.cb_mon.awready) begin
                axi_transaction tx = axi_transaction::type_id::create("aw_tx");
                tx.op_type     = AXI_OP_WRITE;
                tx.id          = vif.cb_mon.awid;
                tx.addr        = vif.cb_mon.awaddr;
                tx.len         = vif.cb_mon.awlen;
                tx.size        = axi_size_e'(vif.cb_mon.awsize);
                tx.burst       = axi_burst_e'(vif.cb_mon.awburst);
                tx.cache       = vif.cb_mon.awcache;
                tx.prot        = vif.cb_mon.awprot;
                tx.start_time  = $time;
                tx.start_cycle = cycle_count;

                `uvm_info("AW_MON", $sformatf("AW Handshake [Cycle %0d]: ID=0x%0h Addr=0x%08h Len=%0d Size=%0d Burst=%s",
                          cycle_count, tx.id, tx.addr, tx.len, tx.size, tx.burst.name()), UVM_HIGH)
                aw_ap.write(tx);
            end
        end
    endtask

    // ------------------------------------------------------------------------
    // Channel 2: W Independent Monitor
    // ------------------------------------------------------------------------
    task monitor_w_channel();
        forever begin
            @(vif.cb_mon);
            if (vif.ARESETn && vif.cb_mon.wvalid && vif.cb_mon.wready) begin
                axi_transaction tx = axi_transaction::type_id::create("w_tx");
                tx.op_type     = AXI_OP_WRITE;
                tx.len         = 0;
                tx.data        = new[1];
                tx.wstrb       = new[1];
                tx.wlast       = new[1];
                tx.data[0]     = vif.cb_mon.wdata;
                tx.wstrb[0]    = vif.cb_mon.wstrb;
                tx.wlast[0]    = vif.cb_mon.wlast;
                tx.start_time  = $time;
                tx.start_cycle = cycle_count;

                `uvm_info("W_MON", $sformatf("W Handshake [Cycle %0d]: Data=0x%08h WSTRB=0x%0h WLAST=%0b",
                          cycle_count, tx.data[0], tx.wstrb[0], tx.wlast[0]), UVM_HIGH)
                w_ap.write(tx);
            end
        end
    endtask

    // ------------------------------------------------------------------------
    // Channel 3: B Independent Monitor
    // ------------------------------------------------------------------------
    task monitor_b_channel();
        forever begin
            @(vif.cb_mon);
            if (vif.ARESETn && vif.cb_mon.bvalid && vif.cb_mon.bready) begin
                axi_transaction tx = axi_transaction::type_id::create("b_tx");
                tx.op_type     = AXI_OP_WRITE;
                tx.id          = vif.cb_mon.bid;
                tx.bresp       = axi_resp_e'(vif.cb_mon.bresp);
                tx.end_time    = $time;
                tx.end_cycle   = cycle_count;

                `uvm_info("B_MON", $sformatf("B Handshake [Cycle %0d]: ID=0x%0h BRESP=%s",
                          cycle_count, tx.id, tx.bresp.name()), UVM_HIGH)
                b_ap.write(tx);
            end
        end
    endtask

    // ------------------------------------------------------------------------
    // Channel 4: AR Independent Monitor
    // ------------------------------------------------------------------------
    task monitor_ar_channel();
        forever begin
            @(vif.cb_mon);
            if (vif.ARESETn && vif.cb_mon.arvalid && vif.cb_mon.arready) begin
                axi_transaction tx = axi_transaction::type_id::create("ar_tx");
                tx.op_type     = AXI_OP_READ;
                tx.id          = vif.cb_mon.arid;
                tx.addr        = vif.cb_mon.araddr;
                tx.len         = vif.cb_mon.arlen;
                tx.size        = axi_size_e'(vif.cb_mon.arsize);
                tx.burst       = axi_burst_e'(vif.cb_mon.arburst);
                tx.cache       = vif.cb_mon.arcache;
                tx.prot        = vif.cb_mon.arprot;
                tx.start_time  = $time;
                tx.start_cycle = cycle_count;

                `uvm_info("AR_MON", $sformatf("AR Handshake [Cycle %0d]: ID=0x%0h Addr=0x%08h Len=%0d Size=%0d Burst=%s",
                          cycle_count, tx.id, tx.addr, tx.len, tx.size, tx.burst.name()), UVM_HIGH)
                ar_ap.write(tx);
            end
        end
    endtask

    // ------------------------------------------------------------------------
    // Channel 5: R Independent Monitor
    // ------------------------------------------------------------------------
    task monitor_r_channel();
        forever begin
            @(vif.cb_mon);
            if (vif.ARESETn && vif.cb_mon.rvalid && vif.cb_mon.rready) begin
                axi_transaction tx = axi_transaction::type_id::create("r_tx");
                tx.op_type     = AXI_OP_READ;
                tx.id          = vif.cb_mon.rid;
                tx.len         = 0;
                tx.data        = new[1];
                tx.rresp       = new[1];
                tx.rlast       = new[1];
                tx.data[0]     = vif.cb_mon.rdata;
                tx.rresp[0]    = axi_resp_e'(vif.cb_mon.rresp);
                tx.rlast[0]    = vif.cb_mon.rlast;
                tx.end_time    = $time;
                tx.end_cycle   = cycle_count;

                `uvm_info("R_MON", $sformatf("R Handshake [Cycle %0d]: ID=0x%0h Data=0x%08h RRESP=%s RLAST=%0b",
                          cycle_count, tx.id, tx.data[0], tx.rresp[0].name(), tx.rlast[0]), UVM_HIGH)
                r_ap.write(tx);
            end
        end
    endtask

endclass : axi_master_monitor

`endif // AXI_MASTER_MONITOR_SV
