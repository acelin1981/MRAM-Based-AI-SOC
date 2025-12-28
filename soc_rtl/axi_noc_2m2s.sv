module axi_noc_2m2s #(
    parameter int AXI_ID_WIDTH   = 4,
    parameter int AXI_ADDR_WIDTH = 32,
    parameter int AXI_DATA_WIDTH = 64
)(
    input  logic clk,
    input  logic rst_n,

    // ------------------------
    // Master 0 ports
    // ------------------------
    input  logic [AXI_ID_WIDTH-1:0]   m0_awid,
    input  logic [AXI_ADDR_WIDTH-1:0] m0_awaddr,
    input  logic [7:0]                m0_awlen,
    input  logic                       m0_awvalid,
    output logic                       m0_awready,

    input  logic [AXI_DATA_WIDTH-1:0] m0_wdata,
    input  logic                       m0_wlast,
    input  logic                       m0_wvalid,
    output logic                       m0_wready,

    output logic [AXI_ID_WIDTH-1:0]   m0_bid,
    output logic [1:0]                m0_bresp,
    output logic                       m0_bvalid,
    input  logic                       m0_bready,

    input  logic [AXI_ID_WIDTH-1:0]   m0_arid,
    input  logic [AXI_ADDR_WIDTH-1:0] m0_araddr,
    input  logic [7:0]                m0_arlen,
    input  logic                       m0_arvalid,
    output logic                       m0_arready,

    output logic [AXI_ID_WIDTH-1:0]   m0_rid,
    output logic [AXI_DATA_WIDTH-1:0] m0_rdata,
    output logic [1:0]                m0_rresp,
    output logic                       m0_rvalid,
    output logic                       m0_rlast,
    input  logic                       m0_rready,

    // ------------------------
    // Master 1 ports
    // ------------------------
    input  logic [AXI_ID_WIDTH-1:0]   m1_awid,
    input  logic [AXI_ADDR_WIDTH-1:0] m1_awaddr,
    input  logic [7:0]                m1_awlen,
    input  logic                       m1_awvalid,
    output logic                       m1_awready,

    input  logic [AXI_DATA_WIDTH-1:0] m1_wdata,
    input  logic                       m1_wlast,
    input  logic                       m1_wvalid,
    output logic                       m1_wready,

    output logic [AXI_ID_WIDTH-1:0]   m1_bid,
    output logic [1:0]                m1_bresp,
    output logic                       m1_bvalid,
    input  logic                       m1_bready,

    input  logic [AXI_ID_WIDTH-1:0]   m1_arid,
    input  logic [AXI_ADDR_WIDTH-1:0] m1_araddr,
    input  logic [7:0]                m1_arlen,
    input  logic                       m1_arvalid,
    output logic                       m1_arready,

    output logic [AXI_ID_WIDTH-1:0]   m1_rid,
    output logic [AXI_DATA_WIDTH-1:0] m1_rdata,
    output logic [1:0]                m1_rresp,
    output logic                       m1_rvalid,
    output logic                       m1_rlast,
    input  logic                       m1_rready,

    // ------------------------
    // Slave 0 ports
    // ------------------------
    output logic [AXI_ID_WIDTH-1:0]   s0_awid,
    output logic [AXI_ADDR_WIDTH-1:0] s0_awaddr,
    output logic [7:0]                s0_awlen,
    output logic                       s0_awvalid,
    input  logic                       s0_awready,

    output logic [AXI_DATA_WIDTH-1:0] s0_wdata,
    output logic                       s0_wlast,
    output logic                       s0_wvalid,
    input  logic                       s0_wready,

    input  logic [AXI_ID_WIDTH-1:0]   s0_bid,
    input  logic [1:0]                s0_bresp,
    input  logic                       s0_bvalid,
    output logic                       s0_bready,

    output logic [AXI_ID_WIDTH-1:0]   s0_arid,
    output logic [AXI_ADDR_WIDTH-1:0] s0_araddr,
    output logic [7:0]                s0_arlen,
    output logic                       s0_arvalid,
    input  logic                       s0_arready,

    input  logic [AXI_ID_WIDTH-1:0]   s0_rid,
    input  logic [AXI_DATA_WIDTH-1:0] s0_rdata,
    input  logic [1:0]                s0_rresp,
    input  logic                       s0_rvalid,
    input  logic                       s0_rlast,
    output logic                       s0_rready,

    // ------------------------
    // Slave 1 ports
    // ------------------------
    output logic [AXI_ID_WIDTH-1:0]   s1_awid,
    output logic [AXI_ADDR_WIDTH-1:0] s1_awaddr,
    output logic [7:0]                s1_awlen,
    output logic                       s1_awvalid,
    input  logic                       s1_awready,

    output logic [AXI_DATA_WIDTH-1:0] s1_wdata,
    output logic                       s1_wlast,
    output logic                       s1_wvalid,
    input  logic                       s1_wready,

    input  logic [AXI_ID_WIDTH-1:0]   s1_bid,
    input  logic [1:0]                s1_bresp,
    input  logic                       s1_bvalid,
    output logic                       s1_bready,

    output logic [AXI_ID_WIDTH-1:0]   s1_arid,
    output logic [AXI_ADDR_WIDTH-1:0] s1_araddr,
    output logic [7:0]                s1_arlen,
    output logic                       s1_arvalid,
    input  logic                       s1_arready,

    input  logic [AXI_ID_WIDTH-1:0]   s1_rid,
    input  logic [AXI_DATA_WIDTH-1:0] s1_rdata,
    input  logic [1:0]                s1_rresp,
    input  logic                       s1_rvalid,
    input  logic                       s1_rlast,
    output logic                       s1_rready
);

    // decode helpers
    function automatic logic is_s0(input logic [AXI_ADDR_WIDTH-1:0] a);
        return (a[31:28] == 4'h0);
    endfunction
    function automatic logic is_s1(input logic [AXI_ADDR_WIDTH-1:0] a);
        return (a[31:28] == 4'h1);
    endfunction

    // selected master per slave for write/read address
    logic s0_w_sel_m0, s0_r_sel_m0;
    logic s1_w_sel_m0, s1_r_sel_m0;

    // fixed-priority select based on valid + address decode
    always_comb begin
        s0_w_sel_m0 = (m0_awvalid && is_s0(m0_awaddr)) || !(m1_awvalid && is_s0(m1_awaddr));
        s1_w_sel_m0 = (m0_awvalid && is_s1(m0_awaddr)) || !(m1_awvalid && is_s1(m1_awaddr));

        s0_r_sel_m0 = (m0_arvalid && is_s0(m0_araddr)) || !(m1_arvalid && is_s0(m1_araddr));
        s1_r_sel_m0 = (m0_arvalid && is_s1(m0_araddr)) || !(m1_arvalid && is_s1(m1_araddr));
    end

    // -------------
    // AW routing
    // -------------
    assign s0_awvalid = (is_s0(m0_awaddr) && m0_awvalid && s0_w_sel_m0) ||
                        (is_s0(m1_awaddr) && m1_awvalid && !s0_w_sel_m0);
    assign s0_awid    = s0_w_sel_m0 ? m0_awid   : m1_awid;
    assign s0_awaddr  = s0_w_sel_m0 ? m0_awaddr : m1_awaddr;
    assign s0_awlen   = s0_w_sel_m0 ? m0_awlen  : m1_awlen;

    assign s1_awvalid = (is_s1(m0_awaddr) && m0_awvalid && s1_w_sel_m0) ||
                        (is_s1(m1_awaddr) && m1_awvalid && !s1_w_sel_m0);
    assign s1_awid    = s1_w_sel_m0 ? m0_awid   : m1_awid;
    assign s1_awaddr  = s1_w_sel_m0 ? m0_awaddr : m1_awaddr;
    assign s1_awlen   = s1_w_sel_m0 ? m0_awlen  : m1_awlen;

    // backpressure to masters
    assign m0_awready = (is_s0(m0_awaddr) ? (s0_w_sel_m0 && s0_awready) :
                         is_s1(m0_awaddr) ? (s1_w_sel_m0 && s1_awready) : 1'b0);
    assign m1_awready = (is_s0(m1_awaddr) ? (!s0_w_sel_m0 && s0_awready) :
                         is_s1(m1_awaddr) ? (!s1_w_sel_m0 && s1_awready) : 1'b0);

    // -------------
    // W routing (demo: assumes W goes to same slave as AW)
    // -------------
    // For simplicity, route W by current address decode of master AWADDR.
    // In a real NOC you track per-master write target after AW handshake.
    assign s0_wvalid = (m0_wvalid && is_s0(m0_awaddr) && s0_w_sel_m0) ||
                       (m1_wvalid && is_s0(m1_awaddr) && !s0_w_sel_m0);
    assign s0_wdata  = s0_w_sel_m0 ? m0_wdata : m1_wdata;
    assign s0_wlast  = s0_w_sel_m0 ? m0_wlast : m1_wlast;

    assign s1_wvalid = (m0_wvalid && is_s1(m0_awaddr) && s1_w_sel_m0) ||
                       (m1_wvalid && is_s1(m1_awaddr) && !s1_w_sel_m0);
    assign s1_wdata  = s1_w_sel_m0 ? m0_wdata : m1_wdata;
    assign s1_wlast  = s1_w_sel_m0 ? m0_wlast : m1_wlast;

    assign m0_wready = (is_s0(m0_awaddr) ? (s0_w_sel_m0 && s0_wready) :
                        is_s1(m0_awaddr) ? (s1_w_sel_m0 && s1_wready) : 1'b0);
    assign m1_wready = (is_s0(m1_awaddr) ? (!s0_w_sel_m0 && s0_wready) :
                        is_s1(m1_awaddr) ? (!s1_w_sel_m0 && s1_wready) : 1'b0);

    // -------------
    // B routing (by ID MSB as source tag in this demo)
    // -------------
    // In real AXI, routing uses outstanding tables; here we use bid[3] as master tag.
    assign m0_bvalid = (s0_bvalid && (s0_bid[3]==1'b0)) || (s1_bvalid && (s1_bid[3]==1'b0));
    assign m1_bvalid = (s0_bvalid && (s0_bid[3]==1'b1)) || (s1_bvalid && (s1_bid[3]==1'b1));

    assign m0_bid    = (s0_bvalid && (s0_bid[3]==1'b0)) ? s0_bid :
                       (s1_bvalid && (s1_bid[3]==1'b0)) ? s1_bid : '0;
    assign m1_bid    = (s0_bvalid && (s0_bid[3]==1'b1)) ? s0_bid :
                       (s1_bvalid && (s1_bid[3]==1'b1)) ? s1_bid : '0;

    assign m0_bresp  = (s0_bvalid && (s0_bid[3]==1'b0)) ? s0_bresp :
                       (s1_bvalid && (s1_bid[3]==1'b0)) ? s1_bresp : 2'b00;
    assign m1_bresp  = (s0_bvalid && (s0_bid[3]==1'b1)) ? s0_bresp :
                       (s1_bvalid && (s1_bid[3]==1'b1)) ? s1_bresp : 2'b00;

    assign s0_bready = (s0_bid[3]==1'b0) ? m0_bready : m1_bready;
    assign s1_bready = (s1_bid[3]==1'b0) ? m0_bready : m1_bready;

    // -------------
    // AR routing
    // -------------
    assign s0_arvalid = (is_s0(m0_araddr) && m0_arvalid && s0_r_sel_m0) ||
                        (is_s0(m1_araddr) && m1_arvalid && !s0_r_sel_m0);
    assign s0_arid    = s0_r_sel_m0 ? m0_arid   : m1_arid;
    assign s0_araddr  = s0_r_sel_m0 ? m0_araddr : m1_araddr;
    assign s0_arlen   = s0_r_sel_m0 ? m0_arlen  : m1_arlen;

    assign s1_arvalid = (is_s1(m0_araddr) && m0_arvalid && s1_r_sel_m0) ||
                        (is_s1(m1_araddr) && m1_arvalid && !s1_r_sel_m0);
    assign s1_arid    = s1_r_sel_m0 ? m0_arid   : m1_arid;
    assign s1_araddr  = s1_r_sel_m0 ? m0_araddr : m1_araddr;
    assign s1_arlen   = s1_r_sel_m0 ? m0_arlen  : m1_arlen;

    assign m0_arready = (is_s0(m0_araddr) ? (s0_r_sel_m0 && s0_arready) :
                         is_s1(m0_araddr) ? (s1_r_sel_m0 && s1_arready) : 1'b0);
    assign m1_arready = (is_s0(m1_araddr) ? (!s0_r_sel_m0 && s0_arready) :
                         is_s1(m1_araddr) ? (!s1_r_sel_m0 && s1_arready) : 1'b0);

    // -------------
    // R routing (by rid[3] as master tag)
    // -------------
    assign m0_rvalid = (s0_rvalid && (s0_rid[3]==1'b0)) || (s1_rvalid && (s1_rid[3]==1'b0));
    assign m1_rvalid = (s0_rvalid && (s0_rid[3]==1'b1)) || (s1_rvalid && (s1_rid[3]==1'b1));

    assign m0_rid    = (s0_rvalid && (s0_rid[3]==1'b0)) ? s0_rid :
                       (s1_rvalid && (s1_rid[3]==1'b0)) ? s1_rid : '0;
    assign m1_rid    = (s0_rvalid && (s0_rid[3]==1'b1)) ? s0_rid :
                       (s1_rvalid && (s1_rid[3]==1'b1)) ? s1_rid : '0;

    assign m0_rdata  = (s0_rvalid && (s0_rid[3]==1'b0)) ? s0_rdata :
                       (s1_rvalid && (s1_rid[3]==1'b0)) ? s1_rdata : '0;
    assign m1_rdata  = (s0_rvalid && (s0_rid[3]==1'b1)) ? s0_rdata :
                       (s1_rvalid && (s1_rid[3]==1'b1)) ? s1_rdata : '0;

    assign m0_rresp  = (s0_rvalid && (s0_rid[3]==1'b0)) ? s0_rresp :
                       (s1_rvalid && (s1_rid[3]==1'b0)) ? s1_rresp : 2'b00;
    assign m1_rresp  = (s0_rvalid && (s0_rid[3]==1'b1)) ? s0_rresp :
                       (s1_rvalid && (s1_rid[3]==1'b1)) ? s1_rresp : 2'b00;

    assign m0_rlast  = (s0_rvalid && (s0_rid[3]==1'b0)) ? s0_rlast :
                       (s1_rvalid && (s1_rid[3]==1'b0)) ? s1_rlast : 1'b0;
    assign m1_rlast  = (s0_rvalid && (s0_rid[3]==1'b1)) ? s0_rlast :
                       (s1_rvalid && (s1_rid[3]==1'b1)) ? s1_rlast : 1'b0;

    assign s0_rready = (s0_rid[3]==1'b0) ? m0_rready : m1_rready;
    assign s1_rready = (s1_rid[3]==1'b0) ? m0_rready : m1_rready;

endmodule