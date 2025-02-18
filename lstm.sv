
module lstm #
(
    parameter WIDTH    = 16,
    localparam WEIGHTS =  4
)
(
    input logic                 clk,
    input logic                 rst,
    
    // weights & biases
    input logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] weight_x,
    input logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] weight_h,
    input logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] bias_x,
    input logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] bias_h,
    
    // memories
    input  logic signed [WIDTH - 1 : 0] C_in,
    input  logic signed [WIDTH - 1 : 0] h_in,
    output logic signed [WIDTH - 1 : 0] C_in,

    // datapath
    input  logic signed [WIDTH - 1 : 0] x_in,
    input  logic                        x_valid,
    output logic                        x_ready,
    output logic signed [WIDTH - 1 : 0] y_out,
    output logic                        y_valid
);

    typedef enum logic [1 : 0] {i, f, g, o} weight_index_t;
    
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] scaled;

    always_ff @(posedge clk) begin
        for(int j = 0; j < WEIGHTS; j = j + 1) begin 
            scaled[j] = x*weight_x[j] + h_in*weight_h[j] + bias_x[j] + bias_h[j];
        end
    end

    // implement sigmoid and tanh functions

        

    
    

endmodule
