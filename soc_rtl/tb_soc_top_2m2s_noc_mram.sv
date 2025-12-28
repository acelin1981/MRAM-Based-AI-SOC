module tb_soc_top_2m2s_noc_mram;
    logic clk, rst_n;
    logic [13:0] write_delay_config;
    logic mcu_done;

    soc_top_2m2s_noc_mram dut (
        .clk(clk),
        .rst_n(rst_n),
        .write_delay_config(write_delay_config),
        .mcu_done(mcu_done)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 0;
        write_delay_config = 14'd8;
        repeat(8) @(posedge clk);
        rst_n = 1;
    end

    initial begin
        $dumpfile("soc_2m2s_noc_mram.vcd");
        $dumpvars(0, tb_soc_top_2m2s_noc_mram);
        @(posedge rst_n);
        wait(mcu_done);
        repeat(20) @(posedge clk);
        $finish;
    end
endmodule