module function_lookup #(
    parameter        DEPTH         =  888,
    parameter signed SCALED_X      =  887,
    parameter signed MIN_Y         = -256,
    parameter signed MAX_Y         =  256,
    parameter signed SCALED_OFFSET =    0,
    parameter string LUT_FILE      = "lut_file.mem"
)
(
    input logic                  clk,
    input logic                  rst,
    input logic signed [15 : 0]  x, 
    input logic                  x_valid,
    output logic signed [15 : 0] y,
    output logic                 y_valid
);

    logic signed [15 : 0] search;
    logic signed [15 : 0] lut;
    logic signed [31 : 0] lut_ext;
    logic signed [31 : 0] y_ext;
    
    assign search = x < 0 ? -x : x;
    assign lut_ext = { {16{lut[15]}}, lut};

    assign y_ext = x < -SCALED_X ? MIN_Y : x > SCALED_X ? MAX_Y : x > 0 ? SCALED_OFFSET + lut_ext : SCALED_OFFSET - lut_ext;
    assign y = y_ext[15 : 0];
    
    localparam ADDR_WIDTH = $clog2(DEPTH);
    
    rom #(
        .DEPTH    (DEPTH),
        .WIDTH    (16),
        .ROM_FILE (LUT_FILE)
    )
    u_rom
    (
        .clk      (clk),
        .raddr    (search[ADDR_WIDTH - 1 : 0]),
        .rdata    (lut)
    );

endmodule
