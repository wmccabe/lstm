module axi_handshake (
    input  logic        clk,
    input  logic        rst,
    input  logic        m_valid,
    output logic        s_valid,
    input  logic        m_ready,
    output logic        state
);

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= 1'b0;
            s_valid <= 1'b0;
        end
        else begin
            unique case (state)
                1'b0: begin
                    if (m_valid) begin
                        state <= 1'b1;
                        s_valid <= 1'b1;
                    end
                    else begin
                        state <= 1'b0;
                        s_valid <= 1'b0;
                    end
                end
                1'b1: begin
                    if (m_ready) begin
                        state <= 1'b0;
                        s_valid <= 1'b0;
                    end
                    else begin
                        state <= 1'b1;
                        s_valid <= 1'b1;
                    end
                end
                default: begin
                    state <= 1'b0;
                    s_valid <= 1'b0;
                end
            endcase
        end
    end

endmodule
