module soc_top_2m2s_noc_mram #(
    parameter int AXI_ID_WIDTH   = 4,
    parameter int AXI_ADDR_WIDTH = 32,
    parameter int AXI_DATA_WIDTH = 64
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [13:0] write_delay_config,
    output logic mcu_done
);

    // Master 0 (MCU)
    logic [AXI_ID_WIDTH-1:0]   m0_awid, m0_bid, m0_arid, m0_rid;
    logic [AXI_ADDR_WIDTH-1:0] m0_awaddr, m0_araddr;
    logic [7:0]                m0_awlen, m0_arlen;
    logic                       m0_awvalid, m0_awready;
    logic [AXI_DATA_WIDTH-1:0] m0_wdata, m0_rdata;
    logic                       m0_wlast, m0_wvalid, m0_wready;
    logic [1:0]                m0_bresp, m0_rresp;
    logic                       m0_bvalid, m0_bready;
    logic                       m0_arvalid, m0_arready;
    logic                       m0_rvalid, m0_rlast, m0_rready;

    // Master 1 (DMA)
    logic [AXI_ID_WIDTH-1:0]   m1_awid, m1_bid, m1_arid, m1_rid;
    logic [AXI_ADDR_WIDTH-1:0] m1_awaddr, m1_araddr;
    logic [7:0]                m1_awlen, m1_arlen;
    logic                       m1_awvalid, m1_awready;
    logic [AXI_DATA_WIDTH-1:0] m1_wdata, m1_rdata;
    logic                       m1_wlast, m1_wvalid, m1_wready;
    logic [1:0]                m1_bresp, m1_rresp;
    logic                       m1_bvalid, m1_bready;
    logic                       m1_arvalid, m1_arready;
    logic                       m1_rvalid, m1_rlast, m1_rready;

    mcu_axi_master_model #(
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) u_mcu (
        .clk(clk), .rst_n(rst_n),
        .done(mcu_done),

        .awid(m0_awid), .awaddr(m0_awaddr), .awlen(m0_awlen), .awvalid(m0_awvalid), .awready(m0_awready),
        .wdata(m0_wdata), .wlast(m0_wlast), .wvalid(m0_wvalid), .wready(m0_wready),
        .bid(m0_bid), .bresp(m0_bresp), .bvalid(m0_bvalid), .bready(m0_bready),
        .arid(m0_arid), .araddr(m0_araddr), .arlen(m0_arlen), .arvalid(m0_arvalid), .arready(m0_arready),
        .rid(m0_rid), .rdata(m0_rdata), .rresp(m0_rresp), .rvalid(m0_rvalid), .rlast(m0_rlast), .rready(m0_rready)
    );

    dma_axi_master_model #(
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) u_dma (
        .clk(clk), .rst_n(rst_n),

        .awid(m1_awid), .awaddr(m1_awaddr), .awlen(m1_awlen), .awvalid(m1_awvalid), .awready(m1_awready),
        .wdata(m1_wdata), .wlast(m1_wlast), .wvalid(m1_wvalid), .wready(m1_wready),
        .bid(m1_bid), .bresp(m1_bresp), .bvalid(m1_bvalid), .bready(m1_bready),
        .arid(m1_arid), .araddr(m1_araddr), .arlen(m1_arlen), .arvalid(m1_arvalid), .arready(m1_arready),
        .rid(m1_rid), .rdata(m1_rdata), .rresp(m1_rresp), .rvalid(m1_rvalid), .rlast(m1_rlast), .rready(m1_rready)
    );

    // Slave 0 wires (MRAM controller)
    logic [AXI_ID_WIDTH-1:0]   s0_awid, s0_bid, s0_arid, s0_rid;
    logic [AXI_ADDR_WIDTH-1:0] s0_awaddr, s0_araddr;
    logic [7:0]                s0_awlen, s0_arlen;
    logic                       s0_awvalid, s0_awready;
    logic [AXI_DATA_WIDTH-1:0] s0_wdata, s0_rdata;
    logic                       s0_wlast, s0_wvalid, s0_wready;
    logic [1:0]                s0_bresp, s0_rresp;
    logic                       s0_bvalid, s0_bready;
    logic                       s0_arvalid, s0_arready;
    logic                       s0_rvalid, s0_rlast, s0_rready;

    // Slave 1 wires (SRAM)
    logic [AXI_ID_WIDTH-1:0]   s1_awid, s1_bid, s1_arid, s1_rid;
    logic [AXI_ADDR_WIDTH-1:0] s1_awaddr, s1_araddr;
    logic [7:0]                s1_awlen, s1_arlen;
    logic                       s1_awvalid, s1_awready;
    logic [AXI_DATA_WIDTH-1:0] s1_wdata, s1_rdata;
    logic                       s1_wlast, s1_wvalid, s1_wready;
    logic [1:0]                s1_bresp, s1_rresp;
    logic                       s1_bvalid, s1_bready;
    logic                       s1_arvalid, s1_arready;
    logic                       s1_rvalid, s1_rlast, s1_rready;

    axi_noc_2m2s #(
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) u_noc (
        .clk(clk), .rst_n(rst_n),

        // M0
        .m0_awid(m0_awid), .m0_awaddr(m0_awaddr), .m0_awlen(m0_awlen), .m0_awvalid(m0_awvalid), .m0_awready(m0_awready),
        .m0_wdata(m0_wdata), .m0_wlast(m0_wlast), .m0_wvalid(m0_wvalid), .m0_wready(m0_wready),
        .m0_bid(m0_bid), .m0_bresp(m0_bresp), .m0_bvalid(m0_bvalid), .m0_bready(m0_bready),
        .m0_arid(m0_arid), .m0_araddr(m0_araddr), .m0_arlen(m0_arlen), .m0_arvalid(m0_arvalid), .m0_arready(m0_arready),
        .m0_rid(m0_rid), .m0_rdata(m0_rdata), .m0_rresp(m0_rresp), .m0_rvalid(m0_rvalid), .m0_rlast(m0_rlast), .m0_rready(m0_rready),

        // M1
        .m1_awid(m1_awid), .m1_awaddr(m1_awaddr), .m1_awlen(m1_awlen), .m1_awvalid(m1_awvalid), .m1_awready(m1_awready),
        .m1_wdata(m1_wdata), .m1_wlast(m1_wlast), .m1_wvalid(m1_wvalid), .m1_wready(m1_wready),
        .m1_bid(m1_bid), .m1_bresp(m1_bresp), .m1_bvalid(m1_bvalid), .m1_bready(m1_bready),
        .m1_arid(m1_arid), .m1_araddr(m1_araddr), .m1_arlen(m1_arlen), .m1_arvalid(m1_arvalid), .m1_arready(m1_arready),
        .m1_rid(m1_rid), .m1_rdata(m1_rdata), .m1_rresp(m1_rresp), .m1_rvalid(m1_rvalid), .m1_rlast(m1_rlast), .m1_rready(m1_rready),

        // S0
        .s0_awid(s0_awid), .s0_awaddr(s0_awaddr), .s0_awlen(s0_awlen), .s0_awvalid(s0_awvalid), .s0_awready(s0_awready),
        .s0_wdata(s0_wdata), .s0_wlast(s0_wlast), .s0_wvalid(s0_wvalid), .s0_wready(s0_wready),
        .s0_bid(s0_bid), .s0_bresp(s0_bresp), .s0_bvalid(s0_bvalid), .s0_bready(s0_bready),
        .s0_arid(s0_arid), .s0_araddr(s0_araddr), .s0_arlen(s0_arlen), .s0_arvalid(s0_arvalid), .s0_arready(s0_arready),
        .s0_rid(s0_rid), .s0_rdata(s0_rdata), .s0_rresp(s0_rresp), .s0_rvalid(s0_rvalid), .s0_rlast(s0_rlast), .s0_rready(s0_rready),

        // S1
        .s1_awid(s1_awid), .s1_awaddr(s1_awaddr), .s1_awlen(s1_awlen), .s1_awvalid(s1_awvalid), .s1_awready(s1_awready),
        .s1_wdata(s1_wdata), .s1_wlast(s1_wlast), .s1_wvalid(s1_wvalid), .s1_wready(s1_wready),
        .s1_bid(s1_bid), .s1_bresp(s1_bresp), .s1_bvalid(s1_bvalid), .s1_bready(s1_bready),
        .s1_arid(s1_arid), .s1_araddr(s1_araddr), .s1_arlen(s1_arlen), .s1_arvalid(s1_arvalid), .s1_arready(s1_arready),
        .s1_rid(s1_rid), .s1_rdata(s1_rdata), .s1_rresp(s1_rresp), .s1_rvalid(s1_rvalid), .s1_rlast(s1_rlast), .s1_rready(s1_rready)
    );

    // -------------------------
    // Slave0: your MRAM AXI slave controller + MRAM macro
    // -------------------------
    logic [AXI_ADDR_WIDTH-1:0] mram_addr;
    logic [AXI_DATA_WIDTH-1:0] mram_wdata;
    logic                      mram_write_en, mram_read_en, mram_cs;
    logic [AXI_DATA_WIDTH-1:0] mram_rdata;
    logic                      mram_ready;
    logic                      mram_pwr_on;
    assign mram_pwr_on = 1'b1;

    axi_mram_slave_final_burst_fifo #(
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .BURST_LEN(16)
    ) u_axi_mram (
        .clk(clk),
        .rst_n(rst_n),
        .write_delay_config(write_delay_config),

        .awid   (s0_awid),
        .awaddr (s0_awaddr),
        .awlen  (s0_awlen),
        .awvalid(s0_awvalid),
        .awready(s0_awready),

        .wdata  (s0_wdata),
        .wlast  (s0_wlast),
        .wvalid (s0_wvalid),
        .wready (s0_wready),

        .bid    (s0_bid),
        .bresp  (s0_bresp),
        .bvalid (s0_bvalid),
        .bready (s0_bready),

        .arid   (s0_arid),
        .araddr (s0_araddr),
        .arlen  (s0_arlen),
        .arvalid(s0_arvalid),
        .arready(s0_arready),

        .rid    (s0_rid),
        .rdata  (s0_rdata),
        .rresp  (s0_rresp),
        .rvalid (s0_rvalid),
        .rlast  (s0_rlast),
        .rready (s0_rready),

        .mram_addr    (mram_addr),
        .mram_wdata   (mram_wdata),
        .mram_write_en(mram_write_en),
        .mram_read_en (mram_read_en),
        .mram_cs      (mram_cs),
        .mram_rdata   (mram_rdata),
        .mram_ready   (mram_ready),
        .mram_pwr_on  (mram_pwr_on)
    );

    mram_model #(
        .ADDR_WIDTH(AXI_ADDR_WIDTH),
        .DATA_WIDTH(AXI_DATA_WIDTH),
        .DEPTH_WORDS(4096),
        .READ_LAT(2)
    ) u_mram (
        .clk(clk), .rst_n(rst_n),
        .mram_addr(mram_addr),
        .mram_wdata(mram_wdata),
        .mram_write_en(mram_write_en),
        .mram_read_en(mram_read_en),
        .mram_cs(mram_cs),
        .mram_rdata(mram_rdata),
        .mram_ready(mram_ready),
        .mram_pwr_on(mram_pwr_on)
    );

    // -------------------------
    // Slave1: SRAM model
    // -------------------------
    axi_ram_slave_model #(
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .DEPTH_WORDS(2048)
    ) u_sram (
        .clk(clk), .rst_n(rst_n),

        .awid(s1_awid), .awaddr(s1_awaddr), .awlen(s1_awlen), .awvalid(s1_awvalid), .awready(s1_awready),
        .wdata(s1_wdata), .wlast(s1_wlast), .wvalid(s1_wvalid), .wready(s1_wready),
        .bid(s1_bid), .bresp(s1_bresp), .bvalid(s1_bvalid), .bready(s1_bready),
        .arid(s1_arid), .araddr(s1_araddr), .arlen(s1_arlen), .arvalid(s1_arvalid), .arready(s1_arready),
        .rid(s1_rid), .rdata(s1_rdata), .rresp(s1_rresp), .rvalid(s1_rvalid), .rlast(s1_rlast), .rready(s1_rready)
    );

endmodule