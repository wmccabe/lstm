module rom #(
    parameter DEPTH = 64,
    parameter WIDTH = 32,
    parameter string ROM_FILE = "rom_file.mem",
    localparam ADDR_WIDTH = $clog2(DEPTH)
)
(
    input  logic                       clk,
    input  logic [ADDR_WIDTH - 1 : 0]  raddr,
    output logic [WIDTH - 1 : 0]       rdata
);

    logic [WIDTH - 1 : 0] ram [DEPTH - 1 : 0];
    initial begin
        $readmemh(ROM_FILE, ram);
    end

    always @(posedge clk) begin
        rdata <= ram[raddr];
    end

endmodule  
    
