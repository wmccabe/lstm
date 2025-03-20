// Dual-Port Block RAM with Two Write Ports
// File: rams_tdp_rf.v
module rams_tdp_rf_rf #(
    parameter WIDTH = 32,
    parameter DEPTH = 256,
    localparam ADDR_WIDTH = $clog2(DEPTH)
)
( 
    input  logic                      clka,
    input  logic                      clkb,
    input  logic                      ena,
    input  logic                      enb,
    input  logic                      wea,
    input  logic                      web,
    input  logic [ADDR_WIDTH - 1 : 0] addra,
    input  logic [ADDR_WIDTH - 1 : 0] addrb,
    input  logic [WIDTH - 1 :0]       dia,
    input  logic [WIDTH - 1 :0]       dib,
    output logic [WIDTH - 1 :0]       doa,
    output logic [WIDTH - 1 :0]       dob
);

    logic  [WIDTH - 1 :0] ram [DEPTH - 1 : 0];

    always @(posedge clka) begin
        if (ena) begin
            if (wea) begin
                ram[addra] <= dia;
            end
            doa <= ram[addra];
        end
    end

    always @(posedge clkb) begin
        if (enb) begin
            if (web) begin
                ram[addrb] <= dib;
            end
            dob <= ram[addrb];
        end
    end
endmodule   
