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
    
    assign search = x < 0 ? -x : x;

    assign y = x < -SCALED_X ? MIN_Y : x > SCALED_X ? MAX_Y : x > 0 ? SCALED_OFFSET + lut : SCALED_OFFSET - lut;
    
    rom #(
        .DEPTH    (DEPTH),
        .WIDTH    (16),
        .ROM_FILE (LUT_FILE)
    )
    u_rom
    (
        .clk      (clk),
        .raddr    (search),
        .rdata    (lut)
    )

endmodule
