`timescale 1ps/1ps
module tb_lstm;

    localparam WEIGHTS = 4;
    localparam WIDTH = 16;
    logic clk = 0;
    logic rst;
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] weight_x;
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] weight_h;
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] bias_x;
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] bias_h;
    logic signed [WIDTH - 1 : 0] C_in;
    logic signed [WIDTH - 1 : 0] h_in;
    logic signed [WIDTH - 1 : 0] x_in;
    logic x_valid;

    // create clock and reset
    always #2500 clk = ~clk;
 
    initial begin
        rst = 1;
        repeat(10) @(posedge clk);
        rst = 0;
    end

    localparam NEG_OFFSET = -32768;

    always @(posedge clk) begin
        if (!rst) begin
            x_valid <= 1'b0;
            repeat(10) @(posedge clk);
            for (int i = 0; i < WEIGHTS; i = i + 1) begin
                weight_x[i] <= NEG_OFFSET + $random%65536;
                weight_h[i] <= NEG_OFFSET + $random%65536;
                bias_x[i] <= NEG_OFFSET + $random%65536;
                bias_h[i] <= NEG_OFFSET + $random%65536;
            end
            C_in <= NEG_OFFSET + $random%65536;
            h_in <= NEG_OFFSET + $random%65536;
            x_in <= NEG_OFFSET + $random%65536;
            x_valid <= 1'b1;
        end
    end

    lstm
    u_lstm_dut
    (
        .clk      ( clk      ),
        .rst      ( rst      ),
        .weight_x ( weight_x ),
        .weight_h ( weight_h ),
        .bias_x   ( bias_x   ),
        .bias_h   ( bias_h   ),
        .C_in     ( C_in     ),
        .h_in     ( h_in     ),
        .C_out    (          ),
        .x_in     ( x_in     ),
        .x_valid  ( x_valid  ),
        .x_ready  (          ),
        .y_out    (          ),
        .y_valid  (          )
    );

endmodule
