
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
    input logic        [WEIGHTS - 1 : 0]                weight_x_valid,
    input logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] weight_h,
    input logic        [WEIGHTS - 1 : 0]                weight_h_valid,
    input logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] bias_x,
    input logic        [WEIGHTS - 1 : 0]                bias_x_valid,
    input logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] bias_h,
    input logic        [WEIGHTS - 1 : 0]                bias_h_valid,
    
    
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
    output logic                        valid,
    output logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] debug,
    output logic signed                                  debug_valid
);

    // Enums correspond to different logic paths in the LSTM
    // i - input gate  [0]
    // f - forget gate [1]
    // g - cell        [2]
    // o - output gate [3]

    typedef enum logic [1 : 0] {i, f, g, o} weight_index_t;
    localparam DLY = 7;
    localparam logic [3:0] use_sigmoid = 4'b1011;

    logic signed [WIDTH - 1 : 0]                  x_in_reg;
    logic signed [WIDTH - 1 : 0]                  h_in_reg;
    logic signed [WIDTH - 1 : 0]                  C_in_reg;
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] weight_x_reg;
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] weight_h_reg;
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] bias_x_reg;
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] bias_h_reg;
    
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] scaled;
    logic signed                                  scaled_valid;
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] activated;
    logic signed [WEIGHTS - 1 : 0][WIDTH - 1 : 0] activated_dly;
    logic signed                                  activated_dly_valid;

    logic signed [WIDTH - 1 : 0] C_out_pre;
    logic signed [WIDTH - 1 : 0] C_out_tanh;

    logic [DLY - 1 : 0] x_in_valid_dly;

    assign debug = scaled;
    assign debug_valid = scaled_valid;

    // register weights and biases
    always_ff @(posedge clk) begin
        for (int i = 0; i < WEIGHTS; i += 1) begin
            if (ready) begin
                if (weight_x_valid[i]) weight_x_reg[i] <= weight_x[i];
                if (weight_h_valid[i]) weight_h_reg[i] <= weight_h[i];
                if (bias_x_valid[i])   bias_x_reg[i]   <= bias_x[i];
                if (bias_h_valid[i])   bias_h_reg[i]   <= bias_h[i];
            end
        end
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

    logic signed [WEIGHTS - 1 : 0][31 : 0] product_x;
    logic signed [WEIGHTS - 1 : 0][31 : 0] product_h;
    logic signed [WEIGHTS - 1 : 0][31 : 0] rescale_x;
    logic signed [WEIGHTS - 1 : 0][31 : 0] rescale_h;

    always_comb begin
        for (int j = 0; j < WEIGHTS; j++) begin
            product_x[j] = x_in_reg*weight_x_reg[j];
            product_h[j] = h_in_reg*weight_h_reg[j];
            rescale_x[j] = product_x[j] >>> 8;
            rescale_h[j] = product_h[j] >>> 8;
        end
    end
        

    // implement weighting and scaling
    always_ff @(posedge clk) begin
        for(int j = 0; j < WEIGHTS; j = j + 1) begin 
            scaled[j] <= rescale_x[j][WIDTH-1 : 0] + rescale_h[j][WIDTH-1 : 0] + bias_x_reg[j] + bias_h_reg[j];
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

    logic signed [31 : 0] product_fC;
    logic signed [31 : 0] product_ig;
    logic signed [31 : 0] product_oCtan;
    logic signed [31 : 0] rescale_fC;
    logic signed [31 : 0] rescale_ig;
    logic signed [31 : 0] rescale_oCtan;

    always_comb begin
        product_fC = activated_dly[f]*C_in_reg;
        product_ig = activated_dly[i]*activated_dly[g];
        product_oCtan = activated_dly[o]*C_out_tanh;
        rescale_fC = product_fC >>> 8;
        rescale_ig = product_ig >>> 8;
        rescale_oCtan = product_oCtan >>> 8;
    end

    // assign long term and short term memories
    always_ff @(posedge clk) begin
        activated_dly <= activated; 
        // long term
        C_out_pre <= rescale_fC[15:0] + rescale_ig[15:0];
        C_out <= C_out_pre;
        // short term
        y_out <= rescale_oCtan[15:0];
        x_in_valid_dly <= {x_in_valid_dly[DLY - 2 : 0], x_in_valid && ready};
    end

    assign valid = x_in_valid_dly[DLY-1];
    assign ready = !(|x_in_valid_dly); 
    assign scaled_valid = x_in_valid_dly[1];
    assign activated_dly_valid = x_in_valid_dly[2];
    
    
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
