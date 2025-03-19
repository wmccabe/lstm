// Simple Dual-Port Block RAM with One Clock
// File: simple_dual_one_clock.v
module simple_dual_one_clock #(
    parameter WIDTH = 32,
    parameter DEPTH = 256,
    localparam ADDR_WIDTH = $clog2(DEPTH)

)
(
    input  logic                      clk,
    input  logic                      ena,
    input  logic                      enb,
    input  logic                      wea,
    input  logic [ADDR_WIDTH - 1 : 0] addra,
    input  logic [ADDR_WIDTH - 1 : 0] addrb,
    input  logic [WIDTH - 1 : 0]      dia,
    output logic [WIDTH - 1 : 0]      dob
);

    logic [WIDTH - 1:0] ram [DEPTH - 1:0];

    always @(posedge clk) begin
        if (ena) begin
            if (wea) begin
                ram[addra] <= dia;
            end
        end
    end

    always @(posedge clk) begin
        if (enb) begin
            dob <= ram[addrb];
        end
    end
endmodule
