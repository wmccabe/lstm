
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
    
    
    // datapath
    output logic                        ready,
    input  logic signed [WIDTH - 1 : 0] C_in,
    input  logic                        C_in_valid,
    input  logic signed [WIDTH - 1 : 0] h_in,
    input  logic                        h_in_valid,
    input  logic signed [WIDTH - 1 : 0] x_in,
    input  logic                        x_in_valid,
    output logic signed [WIDTH - 1 : 0] y_out,
    output logic signed [WIDTH - 1 : 0] C_out,
    output logic                        valid
);

    // Enums correspond to different logic paths in the LSTM
    // i - input gate  [0]
    // f - forget gate [1]
    // g - cell        [2]
    // o - output gate [3]

    typedef enum logic [1 : 0] {i, f, g, o} weight_index_t;
    localparam DLY = 6;
    localparam logic [3:0] use_sigmoid = 4'b1011;

    logic signed [WIDTH - 1 : 0]                  x_in_reg;
    logic signed [WIDTH - 1 : 0]                  h_in_reg;
    logic signed [WIDTH - 1 : 0]                  C_in_reg;
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] weight_x_reg;
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] weight_h_reg;
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] bias_x_reg;
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] bias_h_reg;
    
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] scaled;
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] activated;

    logic signed [WIDTH - 1 : 0] C_out_pre;
    logic signed [WIDTH - 1 : 0] C_out_tanh;

    logic [DLY - 1 : 0] x_in_valid_dly;

    // register weights and biases
    always_ff @(posedge clk) begin
        weight_x_reg <= weight_x;
        weight_h_reg <= weight_h;
        bias_x_reg   <= bias_x;
        bias_h_reg   <= bias_h;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            x_in_reg <= '0;
        end
        else if (ready) begin
            if (x_in_valid) x_in_reg <= x_in;
        end
    end

    always_ff @(posedge clk) begin
        if      (rst)                 h_in_reg <= '0;
        else if (ready && h_in_valid) h_in_reg <= h_in;
        else if (valid)               h_in_reg <= y_out;
    end

    always_ff @(posedge clk) begin
        if (rst)                      C_in_reg <= '0;
        else if (ready && C_in_valid) C_in_reg <= C_in;
        else if (valid)               C_in_reg <= C_out;
    end
        

    // implement weighting and scaling
    always_ff @(posedge clk) begin
        for(int j = 0; j < WEIGHTS; j = j + 1) begin 
            scaled[j] = (x_in_reg*weight_x_reg[j])/256 + (h_in_reg*weight_h_reg[j])/256 + bias_x_reg[j] + bias_h_reg[j];
        end
    end

    // implement sigmoid and tanh activation functions
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
                .y             ( activated[j] ),
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
                .y             ( activated[j] ),
                .y_valid       (              )
            );
        end
    end
    endgenerate

    // assign long term and short term memories
    always_ff @(posedge clk) begin
        // long term
        C_out_pre <= (activated[f]*C_in_reg)/256 + (activated[i]*activated[g])/256;
        C_out <= C_out_pre;
        // short term
        y_out <= (activated[o]*C_out_tanh)/256;
        x_in_valid_dly <= {x_in_valid_dly[DLY - 2 : 0], x_in_valid && ready};
    end

    assign valid = x_in_valid_dly[DLY-1];
    assign ready = !(|x_in_valid_dly); 
    
    
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
