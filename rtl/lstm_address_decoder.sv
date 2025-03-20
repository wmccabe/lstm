module lstm_address_decoder #(
    parameter OFFSET = 0,
    parameter LAYERS = 3,
    localparam WEIGHTS = 4,
    localparam NUM_ADDRESSES = 4*(LAYERS*WEIGHTS) + 2*LAYERS + 1 
)
(
    input  logic [31 : 0]                address,
    input  logic                         write_en,
    output logic [NUM_ADDRESSES - 1 : 0] decode_write_enable
);

    always_comb begin
        decode_write_enable = '0;
        for (int i = 0; i < NUM_ADDRESSES - 1; i++) begin
            if (address == OFFSET + i*4) begin
                decode_write_enable[i] = write_en;
            end
        end
    end

endmodule
