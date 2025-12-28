module axi_ram_slave_model #(
    parameter int AXI_ID_WIDTH   = 4,
    parameter int AXI_ADDR_WIDTH = 32,
    parameter int AXI_DATA_WIDTH = 64,
    parameter int DEPTH_WORDS    = 2048
)(
    input  logic                         clk,
    input  logic                         rst_n,

    // Write Address
    input  logic [AXI_ID_WIDTH-1:0]      awid,
    input  logic [AXI_ADDR_WIDTH-1:0]    awaddr,
    input  logic [7:0]                   awlen,
    input  logic                         awvalid,
    output logic                         awready,

    // Write Data
    input  logic [AXI_DATA_WIDTH-1:0]    wdata,
    input  logic                         wlast,
    input  logic                         wvalid,
    output logic                         wready,

    // Write Response
    output logic [AXI_ID_WIDTH-1:0]      bid,
    output logic [1:0]                   bresp,
    output logic                         bvalid,
    input  logic                         bready,

    // Read Address
    input  logic [AXI_ID_WIDTH-1:0]      arid,
    input  logic [AXI_ADDR_WIDTH-1:0]    araddr,
    input  logic [7:0]                   arlen,
    input  logic                         arvalid,
    output logic                         arready,

    // Read Data
    output logic [AXI_ID_WIDTH-1:0]      rid,
    output logic [AXI_DATA_WIDTH-1:0]    rdata,
    output logic [1:0]                   rresp,
    output logic                         rvalid,
    output logic                         rlast,
    input  logic                         rready
);

    localparam int BYTES_PER_WORD = AXI_DATA_WIDTH/8;

    logic [AXI_DATA_WIDTH-1:0] mem [0:DEPTH_WORDS-1];

    // simple write state
    logic wr_active;
    logic [AXI_ADDR_WIDTH-1:0] wr_addr;
    logic [7:0] wr_left;
    logic [AXI_ID_WIDTH-1:0] wr_id;

    // simple read state
    logic rd_active;
    logic [AXI_ADDR_WIDTH-1:0] rd_addr;
    logic [7:0] rd_left;
    logic [AXI_ID_WIDTH-1:0] rd_id;

    function automatic int unsigned idx(input logic [AXI_ADDR_WIDTH-1:0] a);
        idx = (a / BYTES_PER_WORD) % DEPTH_WORDS;
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awready <= 1'b0;
            wready  <= 1'b0;
            bvalid  <= 1'b0;
            bresp   <= 2'b00;
            bid     <= '0;

            arready <= 1'b0;
            rvalid  <= 1'b0;
            rresp   <= 2'b00;
            rid     <= '0;
            rdata   <= '0;
            rlast   <= 1'b0;

            wr_active <= 1'b0;
            rd_active <= 1'b0;
            wr_addr <= '0; wr_left <= '0; wr_id <= '0;
            rd_addr <= '0; rd_left <= '0; rd_id <= '0;
        end else begin
            // defaults
            awready <= !wr_active && !bvalid;   // accept one write txn
            wready  <= wr_active && !bvalid;    // accept data beats
            arready <= !rd_active && !rvalid;   // accept one read txn

            // write address accept
            if (awvalid && awready) begin
                wr_active <= 1'b1;
                wr_addr   <= awaddr;
                wr_left   <= awlen;
                wr_id     <= awid;
            end

            // write data accept
            if (wr_active && wvalid && wready) begin
                mem[idx(wr_addr)] <= wdata;
                if (wr_left == 0) begin
                    wr_active <= 1'b0;
                    bvalid <= 1'b1;
                    bid <= wr_id;
                    bresp <= 2'b00;
                end else begin
                    wr_left <= wr_left - 1;
                    wr_addr <= wr_addr + BYTES_PER_WORD;
                end
            end

            // write response
            if (bvalid && bready) begin
                bvalid <= 1'b0;
            end

            // read address accept
            if (arvalid && arready) begin
                rd_active <= 1'b1;
                rd_addr   <= araddr;
                rd_left   <= arlen;
                rd_id     <= arid;
                // prime first beat
                rvalid <= 1'b1;
                rid <= arid;
                rdata <= mem[idx(araddr)];
                rresp <= 2'b00;
                rlast <= (arlen == 0);
            end else if (rvalid && rready) begin
                if (rlast) begin
                    rvalid <= 1'b0;
                    rlast <= 1'b0;
                    rd_active <= 1'b0;
                end else begin
                    rd_addr <= rd_addr + BYTES_PER_WORD;
                    rd_left <= rd_left - 1;
                    rdata <= mem[idx(rd_addr + BYTES_PER_WORD)];
                    rlast <= (rd_left == 1);
                end
            end
        end
    end

endmodule