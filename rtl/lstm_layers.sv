module lstm_layers #
(
    parameter LAYERS   =  3,
    parameter WIDTH    = 16,
    localparam WEIGHTS =  4
)
(
    input logic                 clk,
    input logic                 rst,
    
    // weights & biases
    input logic signed [LAYERS * WEIGHTS - 1 : 0][WIDTH - 1 : 0] weight_x,
    input logic        [LAYERS * WEIGHTS - 1 : 0]                weight_x_valid,
    input logic signed [LAYERS * WEIGHTS - 1 : 0][WIDTH - 1 : 0] weight_h,
    input logic        [LAYERS * WEIGHTS - 1 : 0]                weight_h_valid,
    input logic signed [LAYERS * WEIGHTS - 1 : 0][WIDTH - 1 : 0] bias_x,
    input logic        [LAYERS * WEIGHTS - 1 : 0]                bias_x_valid,
    input logic signed [LAYERS * WEIGHTS - 1 : 0][WIDTH - 1 : 0] bias_h,
    input logic        [LAYERS * WEIGHTS - 1 : 0]                bias_h_valid,
    
    // datapath
    output logic                                        ready,
    input  logic signed [LAYERS - 1 : 0][WIDTH - 1 : 0] C_in,
    input  logic        [LAYERS - 1 : 0]                C_in_valid,
    input  logic signed [LAYERS - 1 : 0][WIDTH - 1 : 0] h_in,
    input  logic        [LAYERS - 1 : 0]                h_in_valid,
    input  logic signed                 [WIDTH - 1 : 0] x_in,
    input  logic                                        x_in_valid,
    output logic signed                 [WIDTH - 1 : 0] y_out,
    output logic signed                 [WIDTH - 1 : 0] C_out,
    output logic                                        valid,
    output logic signed [LAYERS*WEIGHTS - 1 : 0][WIDTH - 1 : 0] debug,
    output logic signed [LAYERS-1: 0]                           debug_valid
);

    logic        [LAYERS - 1 : 0]                layer_ready;
    logic signed [LAYERS - 1 : 0][WIDTH - 1 : 0] layer_x_in;
    logic        [LAYERS - 1 : 0]                layer_x_in_valid;
    logic signed [LAYERS - 1 : 0][WIDTH - 1 : 0] layer_y_out;
    logic signed [LAYERS - 1 : 0][WIDTH - 1 : 0] layer_C_out;
    logic        [LAYERS - 1 : 0]                layer_valid;

    assign ready = layer_ready[0];
    
    assign y_out = layer_y_out[LAYERS - 1];
    assign C_out = layer_C_out[LAYERS - 1];
    assign valid = layer_valid[LAYERS - 1];

    generate
    for (genvar layer = 0; layer < LAYERS; layer++) begin
        lstm
        u_lstm
        (
            .clk              (clk),
            .rst              (rst),
            
            // weights & biases
            .weight_x         (weight_x[layer*WEIGHTS +: WEIGHTS]       ),
            .weight_x_valid   (weight_x_valid[layer*WEIGHTS +: WEIGHTS] ),
            .weight_h         (weight_h[layer*WEIGHTS +: WEIGHTS]       ),
            .weight_h_valid   (weight_h_valid[layer*WEIGHTS +: WEIGHTS] ),
            .bias_x           (bias_x[layer*WEIGHTS +: WEIGHTS]         ),
            .bias_x_valid     (bias_x_valid[layer*WEIGHTS +: WEIGHTS]   ),
            .bias_h           (bias_h[layer*WEIGHTS +: WEIGHTS]         ),
            .bias_h_valid     (bias_h_valid[layer*WEIGHTS +: WEIGHTS]   ),
            
            // datapath
            .ready            (layer_ready[layer]      ),
            .C_in             (C_in[layer]             ),
            .C_in_valid       (C_in_valid[layer]       ),
            .h_in             (h_in[layer]             ),
            .h_in_valid       (h_in_valid[layer]       ),
            .x_in             (layer_x_in[layer]       ),
            .x_in_valid       (layer_x_in_valid[layer] ),
            .y_out            (layer_y_out[layer]      ),
            .C_out            (layer_C_out[layer]      ),
            .valid            (layer_valid[layer]      ),
            .debug           (debug[layer*WEIGHTS +: WEIGHTS] ),
            .debug_valid     (debug_valid[layer] )
        );
        
        if (layer == 0) begin
            assign layer_x_in[layer]       = x_in;
            assign layer_x_in_valid[layer] = x_in_valid;
        end
        else begin
            // Connect adjacent layers
            assign layer_x_in[layer]       = layer_y_out[layer - 1];
            assign layer_x_in_valid[layer] = layer_valid[layer - 1];
        end

    end
    endgenerate

endmodule
