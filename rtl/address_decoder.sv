module address_decoder #(
    parameter OFFSET = 0,
    parameter ADDRESS_STEP = 4,
    parameter NUM_ADDRESSES = 32
)
(
    input  logic [31 : 0]                address,
    input  logic                         write_en,
    output logic [NUM_ADDRESSES - 1 : 0] decode_write_enable
);

    always_comb begin
        decode_write_enable = '0;
        for (int i = 0; i < NUM_ADDRESSES; i++) begin
            if (address == OFFSET + i*ADDRESS_STEP) begin
                decode_write_enable[i] = write_en;
            end
        end
    end

endmodule
