module axi4_lite_lstm_layers #(
    parameter WIDTH = 32,
    parameter DEPTH = 256,
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
    localparam NUM_ADDRESSES = (4 * LAYERS * WEIGHTS) + (4 * LAYERS) + 1; 
    logic [31 : 0] write_addr;
    logic          write_en;
    logic [31 : 0] update_addr;
    logic [31 : 0] update_data;
    logic          update_valid;
    logic [NUM_ADDRESSES - 1 : 0] decode_write_enable;

    address_decoder #(
        .OFFSET        (0             ),
        .ADDRESS_STEP  (4             ),
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
        .write_addr   (write_addr   ),
        .write_en     (write_en     ),
        .update_addr  (update_addr  ),
        .update_data  (update_data  ),
        .update_valid (update_valid ),
    );

    localparam LSTM_DATA_WIDTH = 16;

    logic signed [LAYERS * WEIGHTS - 1 : 0][WIDTH - 1 : 0] weight_bias;
    assign weight_bias = {LAYERS*WEIGHTS{wdata[LSTM_DATA_WIDTH - 1 : 0]}};

    lstm_layers #(
        .LAYERS   (LAYERS),
        .WIDTH    (LSTM_DATA_WIDTH)
    )
    u_lstm_layers(
        .clk               (clk),
        .rst               (rst),
        
        // weights & biases
        .weight_x          (weight_bias       ),
        .weight_x_valid    (                  ),
        .weight_h          (weight_bias       ),
        .weight_h_valid    (                  ),
        .bias_x            (weight_bias       ),
        .bias_x_valid      (                  ),
        .bias_h            (weight_bias       ),
        .bias_h_valid      (                  ),
        
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
        output logic                                        valid
    );

endmodule
