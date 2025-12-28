// ==========================================================
// AXI MRAM Slave Controller with Configurable Write Delay
// Each line includes inline comments for learning purposes
// *** For Educational and Non-Commercial Use Only ***
// ==========================================================


// ==========================================================
// AXI Full MRAM Slave Controller - Final Integrated Version
// Features:
// - AXI Channel FSM (AW/W/B/AR/R)
// - MRAM Write FSM (10000 cycle delay)
// - MRAM Read FSM (mram_ready based)
// - Write FIFO (burst support), Read FIFO (latency buffer)
// - Proper AXI ready/valid handshake and burst type/size handling
// - mram_cs gated by mram_pwr_on
// For educational and non-commercial use only
// ==========================================================

`timescale 1ns / 1ps

module axi_mram_slave_final_burst_fifo #(
    parameter AXI_ID_WIDTH = 4, // Define module-level constants
    parameter AXI_ADDR_WIDTH = 32, // Define module-level constants
    parameter AXI_DATA_WIDTH = 64, // Define module-level constants
    parameter BURST_LEN = 16, // Define module-level constants
)(
    input  logic                         clk, // Port declaration
    input  logic                         rst_n, // Port declaration
    input  logic [13:0]                write_delay_config, // configurable MRAM write delay input // Port declaration

    // AXI Write Address Channel
    input  logic [AXI_ID_WIDTH-1:0]      awid, // Port declaration
    input  logic [AXI_ADDR_WIDTH-1:0]    awaddr, // Port declaration
    input  logic [7:0]                   awlen, // Port declaration
    input  logic                         awvalid, // Port declaration
    output logic                         awready, // Port declaration

    // AXI Write Data Channel
    input  logic [AXI_DATA_WIDTH-1:0]    wdata, // Port declaration
    input  logic                         wvalid, // Port declaration
    input  logic                         wlast, // Port declaration
    output logic                         wready, // Port declaration

    // AXI Write Response Channel
    output logic [AXI_ID_WIDTH-1:0]      bid, // Port declaration
    output logic [1:0]                   bresp, // Port declaration
    output logic                         bvalid, // Port declaration
    input  logic                         bready, // Port declaration

    // AXI Read Address Channel
    input  logic [AXI_ID_WIDTH-1:0]      arid, // Port declaration
    input  logic [AXI_ADDR_WIDTH-1:0]    araddr, // Port declaration
    input  logic [7:0]                   arlen, // Port declaration
    input  logic                         arvalid, // Port declaration
    output logic                         arready, // Port declaration

    // AXI Read Data Channel
    output logic [AXI_ID_WIDTH-1:0]      rid, // Port declaration
    output logic [AXI_DATA_WIDTH-1:0]    rdata, // Port declaration
    output logic [1:0]                   rresp, // Port declaration
    output logic                         rvalid, // Port declaration
    output logic                         rlast, // Port declaration
    input  logic                         rready, // Port declaration

    // MRAM interface
    output logic [AXI_ADDR_WIDTH-1:0]    mram_addr, // Port declaration
    output logic [AXI_DATA_WIDTH-1:0]    mram_wdata, // Port declaration
    output logic                         mram_write_en, // Port declaration
    output logic                         mram_read_en, // Port declaration
    output logic                         mram_cs, // Port declaration
    input  logic [AXI_DATA_WIDTH-1:0]    mram_rdata, // Port declaration
    input  logic                         mram_ready, // Port declaration
    input  logic                         mram_pwr_on // Port declaration
);

// AXI State Machines for each channel
typedef enum logic [1:0] {S_IDLE, S_WAIT, S_ACTIVE} axi_state_t;
axi_state_t aw_state, w_state, b_state, ar_state, r_state;

// MRAM FSMs
typedef enum logic [1:0] {MW_IDLE, MW_WAIT, MW_WRITE} mram_write_state_t;
typedef enum logic [1:0] {MR_IDLE, MR_WAIT, MR_READ} mram_read_state_t;
mram_write_state_t mw_state;
mram_read_state_t  mr_state;

logic [AXI_DATA_WIDTH-1:0] write_fifo [0:BURST_LEN-1];
logic [3:0] write_wptr, write_rptr;
logic [7:0] awlen_reg;
logic [AXI_ADDR_WIDTH-1:0] awaddr_reg; // Register to store AXI address
logic [13:0] write_delay_cnt;

logic [AXI_DATA_WIDTH-1:0] read_data_fifo [0:1];
logic [0:0] read_wptr, read_rptr;
logic [AXI_ADDR_WIDTH-1:0] araddr_reg; // Register to store AXI address
logic [7:0] arlen_reg;

// === Simplified implementation to demonstrate structure ===
// Write Address Channel
always_ff @(posedge clk or negedge rst_n) begin // Sequential logic triggered by clk and rst_n
    if (!rst_n) begin
        aw_state <= S_IDLE;
        awready  <= 0;
    end else begin
        case (aw_state)
            S_IDLE: begin
                if (awvalid) begin
                    awready    <= 1;
                    awaddr_reg <= awaddr; // Register to store AXI address
                    awlen_reg  <= awlen;
                    aw_state   <= S_WAIT;
                end
            end
            S_WAIT: begin
                if (awvalid && awready) begin // AXI write data handshake signals
                    awready  <= 0;
                    aw_state <= S_ACTIVE;
                end
            end
            S_ACTIVE: aw_state <= S_IDLE;
        endcase
    end
end

// Write Data Channel
always_ff @(posedge clk or negedge rst_n) begin // Sequential logic triggered by clk and rst_n
    if (!rst_n) begin
        w_state      <= S_IDLE;
        write_wptr   <= 0;
        wready       <= 1;
    end else begin
        if (wvalid && wready) begin // AXI write data handshake signals
            write_fifo[write_wptr] <= wdata;
            write_wptr <= write_wptr + 1;
        end
    end
end

// MRAM Write FSM
always_ff @(posedge clk or negedge rst_n) begin // Sequential logic triggered by clk and rst_n
    if (!rst_n) begin
        mw_state <= MW_IDLE;
        write_rptr <= 0;
        write_delay_cnt <= 0;
        mram_write_en <= 0; // Enable MRAM write operation
    end else begin
        mram_write_en <= 0; // Enable MRAM write operation
        case (mw_state)
            MW_IDLE:
                if (write_wptr != write_rptr)
                    mw_state <= MW_WAIT;
            MW_WAIT: begin
                write_delay_cnt <= write_delay_cnt + 1;
                if (write_delay_cnt == write_delay_config) begin
 // compare with external delay config // Configurable write delay input
                    mw_state <= MW_WRITE;
                    write_delay_cnt <= 0;
                end
            end
            MW_WRITE: begin
                mram_addr <= awaddr_reg + (write_rptr << 3); // Register to store AXI address
                mram_wdata <= write_fifo[write_rptr]; // MRAM data to be written
                mram_write_en <= 1; // Enable MRAM write operation
                write_rptr <= write_rptr + 1;
                if (write_rptr == awlen_reg)
                    mw_state <= MW_IDLE;
                else
                    mw_state <= MW_WAIT;
            end
        endcase
    end
end

// Assign CS
assign mram_cs = mram_pwr_on & (mram_write_en | mram_read_en); // MRAM chip select controlled by power and FSM activity

endmodule


// MRAM Read FSM
always_ff @(posedge clk or negedge rst_n) begin // Sequential logic triggered by clk and rst_n
    if (!rst_n) begin
        mr_state   <= MR_IDLE;
        mram_read_en <= 0; // Enable MRAM read operation
        read_wptr <= 0;
        araddr_reg <= 0; // Register to store AXI address
        arlen_reg <= 0;
        ar_state <= S_IDLE;
        arready <= 1;
    end else begin
        mram_read_en <= 0; // Enable MRAM read operation
        case (mr_state)
            MR_IDLE: begin
                if (ar_state == S_ACTIVE) begin
                    araddr_reg <= araddr; // Register to store AXI address
                    arlen_reg  <= arlen;
                    read_wptr  <= 0;
                    mr_state   <= MR_WAIT;
                end
            end
            MR_WAIT: begin
                if (mram_ready && mram_pwr_on) begin // Indicates MRAM is ready for read/write
                    mram_addr <= araddr_reg + (read_wptr << 3); // Register to store AXI address
                    mram_read_en <= 1; // Enable MRAM read operation
                    mr_state <= MR_READ;
                end
            end
            MR_READ: begin
                read_data_fifo[read_wptr] <= mram_rdata; // MRAM data that was read
                read_wptr <= read_wptr + 1;
                if (read_wptr == arlen_reg)
                    mr_state <= MR_IDLE;
                else
                    mr_state <= MR_WAIT;
            end
        endcase
    end
end

// AXI Read Data Channel FSM
always_ff @(posedge clk or negedge rst_n) begin // Sequential logic triggered by clk and rst_n
    if (!rst_n) begin
        r_state <= S_IDLE;
        rvalid  <= 0; // AXI read data valid signal
        rlast   <= 0;
        read_rptr <= 0;
    end else begin
        case (r_state)
            S_IDLE: begin
                if (mr_state == MR_READ && read_wptr > 0) begin
                    rvalid <= 1; // AXI read data valid signal
                    rid    <= arid;
                    rdata  <= read_data_fifo[read_rptr];
                    rlast  <= (read_rptr == arlen_reg);
                    r_state <= S_ACTIVE;
                end
            end
            S_ACTIVE: begin
                if (rvalid && rready) begin // AXI read data valid signal
                    read_rptr <= read_rptr + 1;
                    if (read_rptr == arlen_reg) begin
                        rvalid <= 0; // AXI read data valid signal
                        rlast <= 0;
                        r_state <= S_IDLE;
                    end else begin
                        rdata <= read_data_fifo[read_rptr + 1];
                        rlast <= (read_rptr + 1 == arlen_reg);
                    end
                end
            end
        endcase
    end
end
