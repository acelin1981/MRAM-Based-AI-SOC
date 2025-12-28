module mram_model #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 64,
    parameter int DEPTH_WORDS = 4096,
    parameter int READ_LAT = 2
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [ADDR_WIDTH-1:0]  mram_addr,
    input  logic [DATA_WIDTH-1:0]  mram_wdata,
    input  logic                   mram_write_en,
    input  logic                   mram_read_en,
    input  logic                   mram_cs,
    output logic [DATA_WIDTH-1:0]  mram_rdata,
    output logic                   mram_ready,
    input  logic                   mram_pwr_on
);

    localparam int BYTES_PER_WORD = DATA_WIDTH/8;
    logic [DATA_WIDTH-1:0] mem [0:DEPTH_WORDS-1];

    logic [ADDR_WIDTH-1:0] rd_addr_q [0:READ_LAT-1];
    logic                  rd_vld_q  [0:READ_LAT-1];
    int i;

    function automatic int unsigned idx(input logic [ADDR_WIDTH-1:0] a);
        idx = (a / BYTES_PER_WORD) % DEPTH_WORDS;
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mram_rdata <= '0;
            mram_ready <= 1'b0;
            for (i=0;i<READ_LAT;i++) begin
                rd_addr_q[i] <= '0;
                rd_vld_q[i]  <= 1'b0;
            end
        end else begin
            mram_ready <= 1'b0;

            if (mram_pwr_on && mram_cs && mram_write_en) begin
                mem[idx(mram_addr)] <= mram_wdata;
            end

            // shift pipeline
            for (i=READ_LAT-1;i>0;i--) begin
                rd_addr_q[i] <= rd_addr_q[i-1];
                rd_vld_q[i]  <= rd_vld_q[i-1];
            end
            rd_addr_q[0] <= mram_addr;
            rd_vld_q[0]  <= (mram_pwr_on && mram_cs && mram_read_en);

            if (rd_vld_q[READ_LAT-1]) begin
                mram_rdata <= mem[idx(rd_addr_q[READ_LAT-1])];
                mram_ready <= 1'b1;
            end
        end
    end
endmodule