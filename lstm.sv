
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
    output logic signed [WIDTH - 1 : 0] C_out,

    // datapath
    input  logic signed [WIDTH - 1 : 0] x_in,
    input  logic                        x_valid,
    output logic                        x_ready,
    output logic signed [WIDTH - 1 : 0] y_out,
    output logic                        y_valid
);

    // Enums correspond to different logic paths in the LSTM
    // i - input gate
    // f - forget gate
    // g - cell
    // o - output gate

    typedef enum logic [1 : 0] {i, f, g, o} weight_index_t;
    localparam logic [3:0] use_sigmoid = 4'b1101;
    
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] scaled;

    always_ff @(posedge clk) begin
        for(int j = 0; j < WEIGHTS; j = j + 1) begin 
            scaled[j] = (x_in*weight_x[j] + h_in*weight_h[j] + bias_x[j] + bias_h[j]) >> 8;
        end
    end

    // implement sigmoid and tanh functions
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] looked_up;

    generate
    for (genvar j = 0; j < WEIGHTS; j = j + 1) begin
        if (use_sigmoid[j]) begin
            function_lookup #(
                .DEPTH         (  1597),
                .SCALED_X      (  1596),
                .MIN_Y         (     0),
                .MAX_Y         (   256),
                .SCALED_OFFSET (   128),
                .LUT_FILE      ( "sigmoid.mem")
            )
            u_sigmoid 
            (
                .clk           ( clk          ),
                .rst           ( rst          ),
                .x             ( scaled[j]    ),
                .x_valid       (              ),
                .y             ( looked_up[j] ),
                .y_valid       (              )
            );
        end
        else begin
            function_lookup #(
                .DEPTH         (        888),
                .SCALED_X      (        887),
                .MIN_Y         (       -256),
                .MAX_Y         (        256),
                .SCALED_OFFSET (          0),
                .LUT_FILE      ( "tanh.mem")
            )
            u_tanh    
            (
                .clk           ( clk          ),
                .rst           ( rst          ),
                .x             ( scaled[j]    ),
                .x_valid       (              ),
                .y             ( looked_up[j] ),
                .y_valid       (              )
            );
        end
    end
    endgenerate

    // assign long term and short term memories
    logic signed [WIDTH - 1 : 0] C_out_pre;
    always_ff @(posedge clk) begin
        // long term
        C_out_pre <= (looked_up[f]*C_in + looked_up[i]*looked_up[g]) >> 8;
        C_out <= C_out_pre;
        // short term
        y_out <= (looked_up[o]*C_out_tanh) >> 8; 
    end
    
    logic signed [WIDTH - 1 : 0] C_out_tanh;
    
    function_lookup #(
        .DEPTH         (        888),
        .SCALED_X      (        887),
        .MIN_Y         (       -256),
        .MAX_Y         (        256),
        .SCALED_OFFSET (          0),
        .LUT_FILE      ( "tanh.mem")
    )
    u_tanh    
    (
        .clk           ( clk        ),
        .rst           ( rst        ),
        .x             ( C_out_pre  ),
        .x_valid       (            ),
        .y             ( C_out_tanh ),
        .y_valid       (            )
    );

endmodule
