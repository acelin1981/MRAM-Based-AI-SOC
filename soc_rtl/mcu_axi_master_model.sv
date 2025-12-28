module mcu_axi_master_model #(
    parameter int AXI_ID_WIDTH   = 4,
    parameter int AXI_ADDR_WIDTH = 32,
    parameter int AXI_DATA_WIDTH = 64
)(
    input  logic clk,
    input  logic rst_n,

    output logic done,

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

    localparam int BYTES_PER_WORD = AXI_DATA_WIDTH/8;

    typedef enum logic [3:0] {
        ST_IDLE,
        ST_WA,
        ST_WD,
        ST_WB,
        ST_RA,
        ST_RD,
        ST_DONE
    } state_t;

    state_t st;

    int unsigned beat;
    int unsigned nbeats;
    logic [AXI_ADDR_WIDTH-1:0] base_addr;
    logic [AXI_DATA_WIDTH-1:0] exp;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done   <= 1'b0;
            st     <= ST_IDLE;
            beat   <= 0;
            nbeats <= 0;
            base_addr <= '0;

            awid <= 4'h1; awaddr <= '0; awlen <= '0; awvalid <= 1'b0;
            wdata <= '0; wlast <= 1'b0; wvalid <= 1'b0;
            bready <= 1'b0;

            arid <= 4'h1; araddr <= '0; arlen <= '0; arvalid <= 1'b0;
            rready <= 1'b0;
        end else begin
            case (st)
                ST_IDLE: begin
                    // Program: write 4 beats to MRAM @0x0000_1000, then read back 4 beats
                    base_addr <= 32'h0000_1000;
                    nbeats    <= 4;
                    beat      <= 0;
                    awid      <= 4'h1;
                    awaddr    <= 32'h0000_1000;
                    awlen     <= 4-1;
                    awvalid   <= 1'b1;
                    st        <= ST_WA;
                end

                ST_WA: begin
                    if (awvalid && awready) begin
                        awvalid <= 1'b0;
                        // start data
                        wvalid <= 1'b1;
                        wlast  <= 1'b0;
                        beat   <= 0;
                        wdata  <= {32'hMCU0000 + 0, 32'hA5A50000 + 0};
                        st     <= ST_WD;
                    end
                end

                ST_WD: begin
                    if (wvalid && wready) begin
                        if (beat == nbeats-1) begin
                            wlast  <= 1'b0;
                            wvalid <= 1'b0;
                            bready <= 1'b1;
                            st     <= ST_WB;
                        end else begin
                            beat <= beat + 1;
                            wdata <= {32'hMCU0000 + (beat+1), 32'hA5A50000 + (beat+1)};
                            wlast <= (beat+1 == nbeats-1);
                        end
                    end
                end

                ST_WB: begin
                    if (bvalid && bready) begin
                        bready <= 1'b0;
                        // now read back
                        beat <= 0;
                        arid <= 4'h1;
                        araddr <= base_addr;
                        arlen <= nbeats-1;
                        arvalid <= 1'b1;
                        st <= ST_RA;
                    end
                end

                ST_RA: begin
                    if (arvalid && arready) begin
                        arvalid <= 1'b0;
                        rready  <= 1'b1;
                        st <= ST_RD;
                    end
                end

                ST_RD: begin
                    if (rvalid && rready) begin
                        exp = {32'hMCU0000 + beat, 32'hA5A50000 + beat};
                        // For demo: just ignore compare in synthesizable style; in sim TB can check too.
                        beat <= beat + 1;
                        if (rlast) begin
                            rready <= 1'b0;
                            st <= ST_DONE;
                        end
                    end
                end

                ST_DONE: begin
                    done <= 1'b1;
                end

                default: st <= ST_IDLE;
            endcase
        end
    end
endmodule