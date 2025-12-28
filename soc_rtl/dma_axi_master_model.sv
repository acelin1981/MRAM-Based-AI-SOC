module dma_axi_master_model #(
    parameter int AXI_ID_WIDTH   = 4,
    parameter int AXI_ADDR_WIDTH = 32,
    parameter int AXI_DATA_WIDTH = 64
)(
    input  logic clk,
    input  logic rst_n,

    // AXI Write Address
    output logic [AXI_ID_WIDTH-1:0]      awid,
    output logic [AXI_ADDR_WIDTH-1:0]    awaddr,
    output logic [7:0]                   awlen,
    output logic                         awvalid,
    input  logic                         awready,

    // AXI Write Data
    output logic [AXI_DATA_WIDTH-1:0]    wdata,
    output logic                         wlast,
    output logic                         wvalid,
    input  logic                         wready,

    // AXI Write Response
    input  logic [AXI_ID_WIDTH-1:0]      bid,
    input  logic [1:0]                   bresp,
    input  logic                         bvalid,
    output logic                         bready,

    // AXI Read Address
    output logic [AXI_ID_WIDTH-1:0]      arid,
    output logic [AXI_ADDR_WIDTH-1:0]    araddr,
    output logic [7:0]                   arlen,
    output logic                         arvalid,
    input  logic                         arready,

    // AXI Read Data
    input  logic [AXI_ID_WIDTH-1:0]      rid,
    input  logic [AXI_DATA_WIDTH-1:0]    rdata,
    input  logic [1:0]                   rresp,
    input  logic                         rvalid,
    input  logic                         rlast,
    output logic                         rready
);
    // DMA: a short write to SRAM region, overlapping with MCU
    localparam int BYTES_PER_WORD = AXI_DATA_WIDTH/8;

    typedef enum logic [2:0] {D_IDLE, D_WA, D_WD, D_WB, D_DONE} dstate_t;
    dstate_t st;
    int unsigned beat;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= D_IDLE;
            beat <= 0;
            awid <= 4'h3; awaddr <= '0; awlen <= '0; awvalid <= 1'b0;
            wdata <= '0; wlast <= 1'b0; wvalid <= 1'b0;
            bready <= 1'b0;
            arid <= 4'h3; araddr <= '0; arlen <= '0; arvalid <= 1'b0;
            rready <= 1'b0;
        end else begin
            case (st)
                D_IDLE: begin
                    // start at some later time to overlap
                    if ($time > 200) begin
                        awid <= 4'h3;
                        awaddr <= 32'h1000_0040; // SRAM window
                        awlen <= 2-1;
                        awvalid <= 1'b1;
                        beat <= 0;
                        st <= D_WA;
                    end
                end
                D_WA: begin
                    if (awvalid && awready) begin
                        awvalid <= 1'b0;
                        wvalid <= 1'b1;
                        wdata <= {32'hDMA00000, 32'h5A5A0000};
                        wlast <= 1'b0;
                        st <= D_WD;
                    end
                end
                D_WD: begin
                    if (wvalid && wready) begin
                        if (beat == 1) begin
                            wvalid <= 1'b0;
                            bready <= 1'b1;
                            st <= D_WB;
                        end else begin
                            beat <= beat + 1;
                            wdata <= {32'hDMA00000 + 1, 32'h5A5A0000 + 1};
                            wlast <= 1'b1;
                        end
                    end
                end
                D_WB: begin
                    if (bvalid && bready) begin
                        bready <= 1'b0;
                        st <= D_DONE;
                    end
                end
                D_DONE: begin end
            endcase
        end
    end
endmodule