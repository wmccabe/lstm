module axi4_lite_lstm_layers_wrapper #(
    parameter AXI_WIDTH = 32,
    parameter AXI_DEPTH = 512,
    parameter LAYERS = 4,
    localparam WEIGHTS = 4,
    localparam ADDR_WIDTH = $clog2(AXI_DEPTH)
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
    input            rready
);

    axi4_lite_lstm_layers #(
        .AXI_WIDTH  (AXI_WIDTH  ),
        .AXI_DEPTH  (AXI_DEPTH  ),
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
        .rready     (rready     )
    );

endmodule
