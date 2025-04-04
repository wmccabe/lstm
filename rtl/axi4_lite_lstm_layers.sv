import version_package::*;

module axi4_lite_lstm_layers #(
    parameter WIDTH = 32,
    parameter DEPTH = 512,
    parameter LAYERS = 4,
    localparam WEIGHTS = 4,
    localparam ADDR_WIDTH = $clog2(DEPTH)
)
(
    input  logic          clk,
    input  logic          rst,
    // AXI4-Lite Interface
    // write address channel
    input  logic [31 : 0] awaddr,
    input  logic  [2 : 0] awprot,
    input  logic          awvalid,
    output logic          awready,
    // write data channel 
    input  logic [31 : 0] wdata,
    input  logic  [3 : 0] wstrb,
    input  logic          wvalid,
    output logic          wready,
    // write response
    output logic  [1 : 0] bresp,
    output logic          bvalid,
    input  logic          bready,
    // read address channel
    input  logic [31 : 0] araddr,
    input  logic  [2 : 0] arprot,
    input  logic          arvalid,
    output logic          arready,
    // read data channel
    output logic [31 : 0] rdata,
    output logic  [1 : 0] rresp,
    output logic          rvalid,
    input  logic          rready
 );

    localparam NUM_ADDRESSES = (4 * LAYERS * WEIGHTS) + (2 * LAYERS) + 1;
    localparam ADDRESS_STEP = 4; 
    logic [31 : 0] write_addr;
    logic [31 : 0] write_data;
    logic          write_en;
    logic          lstm_ready;
    logic          lstm_valid;
    logic [31 : 0] update_addr;
    logic [31 : 0] update_data;
    logic          update_valid;
    logic [NUM_ADDRESSES - 1 : 0] decode_write_enable;

    address_decoder #(
        .OFFSET        (0             ),
        .ADDRESS_STEP  (ADDRESS_STEP  ),
        .NUM_ADDRESSES (NUM_ADDRESSES )
    )
    u_address_decoder(
        .address             (write_addr          ),
        .write_en            (write_en            ),
        .decode_write_enable (decode_write_enable )
    );

    axi4_lite_slave #(
        .WIDTH        (WIDTH),
        .DEPTH        (DEPTH)
    )
    u_axi4_lite_slave(
        .clk          (clk          ), 
        .rst          (rst          ), 
        .awaddr       (awaddr       ), 
        .awprot       (awprot       ),
        .awvalid      (awvalid      ),
        .awready      (awready      ), 
        .wdata        (wdata        ),
        .wstrb        (wstrb        ),
        .wvalid       (wvalid       ),
        .wready       (wready       ),
        .bresp        (bresp        ),
        .bvalid       (bvalid       ),
        .bready       (bready       ),
        .araddr       (araddr       ),
        .arprot       (arprot       ),
        .arvalid      (arvalid      ),
        .arready      (arready      ),
        .rdata        (rdata        ),
        .rresp        (rresp        ),
        .rvalid       (rvalid       ),
        .rready       (rready       ),
        .user_ready   (lstm_ready   ),
        .write_addr   (write_addr   ),
        .write_data   (write_data   ),
        .write_en     (write_en     ),
        .update_addr  (update_addr  ),
        .update_data  (update_data  ),
        .update_valid (update_valid )
    );

    localparam LSTM_DATA_WIDTH = 16;

    logic signed [LAYERS * WEIGHTS - 1 : 0][LSTM_DATA_WIDTH - 1 : 0] weight_bias;
    logic signed [LAYERS - 1 : 0][LSTM_DATA_WIDTH - 1 : 0] per_layer_input;
    assign weight_bias = {LAYERS*WEIGHTS{write_data[LSTM_DATA_WIDTH - 1 : 0]}};
    assign per_layer_input = {LAYERS{write_data[LSTM_DATA_WIDTH - 1 : 0]}};
    // lstm layer valid offsets
    localparam WEIGHT_X = 0;
    localparam WEIGHT_H = LAYERS * WEIGHTS + WEIGHT_X;
    localparam BIAS_X   = LAYERS * WEIGHTS + WEIGHT_H;
    localparam BIAS_H   = LAYERS * WEIGHTS + BIAS_X;
    localparam C_IN     = LAYERS * WEIGHTS + BIAS_H;
    localparam H_IN     = LAYERS + C_IN;
    localparam X_IN     = LAYERS + H_IN;

    localparam Y_OUT = NUM_ADDRESSES*ADDRESS_STEP;
    localparam C_OUT = Y_OUT + ADDRESS_STEP;
    localparam VERSION = C_OUT + ADDRESS_STEP; 

    logic [15 : 0] y_out;
    logic          y_out_valid;
    logic [15 : 0] C_out;
    logic [15 : 0] C_out_dly;
    logic          valid_dly;

    lstm_layers #(
        .LAYERS   (LAYERS),
        .WIDTH    (LSTM_DATA_WIDTH)
    )
    u_lstm_layers(
        .clk            (clk),
        .rst            (rst),
        
        // weights & biases
        .weight_x       (weight_bias                  ),
        .weight_x_valid (decode_write_enable[WEIGHT_X +: LAYERS * WEIGHTS] ),
        .weight_h       (weight_bias                                       ),
        .weight_h_valid (decode_write_enable[WEIGHT_H +: LAYERS * WEIGHTS] ),
        .bias_x         (weight_bias                                       ),
        .bias_x_valid   (decode_write_enable[BIAS_X +: LAYERS * WEIGHTS]   ),
        .bias_h         (weight_bias                                       ),
        .bias_h_valid   (decode_write_enable[BIAS_H +: LAYERS * WEIGHTS]   ),
        
        // datapath
        .ready          (lstm_ready                                        ),
        .C_in           (per_layer_input                                   ),
        .C_in_valid     (decode_write_enable[C_IN +: LAYERS]               ),
        .h_in           (per_layer_input                                   ),
        .h_in_valid     (decode_write_enable[H_IN +: LAYERS]               ),
        .x_in           (write_data[LSTM_DATA_WIDTH - 1 : 0]               ),
        .x_in_valid     (decode_write_enable[X_IN]                         ),
        .y_out          (y_out                                             ),
        .C_out          (C_out                                             ),
        .valid          (lstm_valid                                        )
     );
    
    assign y_out_valid = lstm_valid;
   
    // delay outputs to update using single port 
    always_ff @(posedge clk) begin
        C_out_dly <= C_out;
        valid_dly <= lstm_valid;
    end

    logic write_version;
    logic [15 : 0] rst_dly;

    // add versioning
    always_ff @(posedge clk) begin
        if (rst) begin
            write_version <= 1'b0;
            rst_dly <= '1;
        end
        else begin
            rst_dly <= {rst_dly[14:0], rst};
            write_version <= (rst_dly == 16'h8000);
        end
    end
    
    assign update_addr = write_version ? VERSION: lstm_valid ? Y_OUT : C_OUT; 
    assign update_data = write_version ? VERSION_REGISTER : lstm_valid ? {16'h0000, y_out} : {16'h0000, C_out_dly}; 
    assign update_valid = write_version || lstm_valid || valid_dly;

endmodule
