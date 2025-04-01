module axi4_lite_lstm_layers_wrapper #(
    parameter WIDTH = 32,
    parameter DEPTH = 512,
    parameter LAYERS = 1,
    localparam WEIGHTS = 4,
    localparam ADDR_WIDTH = $clog2(DEPTH)
)
(
    input            clk,
    input            rst,
    // AXI4-Lite Interface
    // write address channel
    input   [31 : 0] awaddr,
    input    [2 : 0] awprot,
    input            awvalid,
    output           awready,
    // write data channel 
    input   [31 : 0] wdata,
    input    [3 : 0] wstrb,
    input            wvalid,
    output           wready,
    // write response
    output   [1 : 0] bresp,
    output           bvalid,
    input            bready,
    // read address channel
    input   [31 : 0] araddr,
    input    [2 : 0] arprot,
    input            arvalid,
    output           arready,
    // read data channel
    output  [31 : 0] rdata,
    output   [1 : 0] rresp,
    output           rvalid,
    input            rready,
    output  [15 : 0] y_out,
    output           y_out_valid,
    output signed [LAYERS*WEIGHTS - 1 : 0][15 : 0] scaled,
    output signed [LAYERS - 1 : 0]                 scaled_valid
);

    axi4_lite_lstm_layers #(
        .WIDTH      (WIDTH      ),
        .DEPTH      (DEPTH      ),
        .LAYERS     (LAYERS     )
    ) u_axi4_lite_lstm_layers(
        .clk        (clk        ),
        .rst        (rst        ),
        .awaddr     (awaddr     ),
        .awprot     (awprot     ),
        .awvalid    (awvalid    ),
        .awready    (awready    ),
        .wdata      (wdata      ),
        .wstrb      (wstrb      ),
        .wvalid     (wvalid     ),
        .wready     (wready     ),
        .bresp      (bresp      ),
        .bvalid     (bvalid     ),
        .bready     (bready     ),
        .araddr     (araddr     ),
        .arprot     (arprot     ),
        .arvalid    (arvalid    ),
        .arready    (arready    ),
        .rdata      (rdata      ),
        .rresp      (rresp      ),
        .rvalid     (rvalid     ),
        .rready     (rready     ),
        .y_out      (y_out      ),
        .y_out_valid (y_out_valid      ),
        .scaled     (scaled     ),
        .scaled_valid (scaled_valid     )
    );

endmodule
