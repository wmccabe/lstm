module axi4_lite_slave #(
    parameter WIDTH = 32,
    parameter DEPTH = 256,
    localparam ADDR_WIDTH = $clog2(DEPTH)
)
(
    input  logic          clk,
    input  logic          rst,
    // AXI4-Lite Interface
    // write address channel
    input  logic [31 : 0] awaddr,
    input  logic  [2 : 0] awprot,
    input  logic          awvalid,
    output logic          awready,
    // write data channel 
    input  logic [31 : 0] wdata,
    input  logic  [3 : 0] wstrb,
    input  logic          wvalid,
    output logic          wready,
    // write response
    output logic  [1 : 0] bresp,
    output logic          bvalid,
    input  logic          bready,
    // read address channel
    input  logic [31 : 0] araddr,
    input  logic  [2 : 0] arprot,
    input  logic          arvalid,
    output logic          arready,
    // read data channel
    output logic [31 : 0] rdata,
    output logic  [1 : 0] rresp,
    output logic          rvalid,
    input  logic          rready,

    // User logic interface
    input  logic          user_ready,
    output logic [31 : 0] write_addr,
    output logic [31 : 0] write_data,
    output logic          write_en,
    input  logic [31 : 0] update_addr,
    input  logic [31 : 0] update_data,
    input  logic          update_valid
);

    // write address logic
    logic [31 : 0] write_addr_reg;
    logic [31 : 0] write_data_reg;
     
    assign bresp = 2'b00;
 
    typedef enum {IDLE, WAIT_ADDR, WAIT_DATA, SEND_ACK} write_state_t;
    write_state_t write_state;
    
    assign awready = (!rst) && user_ready && (write_state inside {IDLE, WAIT_ADDR}); 
    assign wready = (!rst) && user_ready && (write_state inside {IDLE, WAIT_DATA});

    assign write_addr = awvalid ? awaddr : write_addr_reg;
    assign write_data = wvalid ? wdata : write_data_reg;

    always_comb begin
        if (rst) begin
            write_en = 1'b0;
        end
        else begin
            unique case (write_state)
                IDLE:      write_en = awvalid && wvalid;
                WAIT_ADDR: write_en = awvalid;
                WAIT_DATA: write_en = wvalid;
                default:   write_en = 1'b0;
            endcase
        end
    end
     
    always_ff @(posedge clk) begin
        if (awvalid) begin
            write_addr_reg <= awaddr;
        end
        if (wvalid) begin
            write_data_reg <= wdata;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            write_state <= IDLE;
            bvalid <= 1'b0;
        end
        else begin
            unique case (write_state)
                IDLE: begin
                    if (awvalid && wvalid && user_ready) begin
                        write_state <= SEND_ACK;
                        bvalid <= 1'b1;
                    end
                    else if (awvalid && user_ready) begin
                        write_state <= WAIT_DATA;
                        bvalid <= 1'b0;
                    end
                    else if (wvalid && user_ready) begin
                        write_state <= WAIT_ADDR;
                        bvalid <= 1'b0;
                    end
                    else begin
                        write_state <= IDLE;
                        bvalid <= 1'b0;
                    end
                end
                WAIT_DATA: begin
                    if (wvalid && user_ready) begin
                        write_state <= SEND_ACK;
                        bvalid <= 1'b1;
                    end
                end
                WAIT_ADDR: begin
                    if (awvalid && user_ready) begin
                        write_state <= SEND_ACK;
                        bvalid <= 1'b1;
                    end
                end
                SEND_ACK: begin
                    if (bready) begin
                        bvalid <= 1'b0;
                        write_state <= IDLE;
                    end
                end
                default: begin
                    write_state <= IDLE;
                    bvalid <= 1'b0;
                end
            endcase
        end
    end
             
    // read data logic
    logic read_state;
    logic [31 : 0] read_addr;
    logic [31 : 0] read_addr_reg;
    assign read_addr = (arvalid && arready) ? araddr : read_addr_reg;
    assign arready = !rst && (read_state == 1'b0);
    assign rresp = 2'b00; // OKAY response

    axi_handshake 
    u_read_handshake (
        .clk      (clk       ),
        .rst      (rst       ),
        .m_valid  (arvalid   ),
        .s_valid  (rvalid    ),
        .m_ready  (rready    ),
        .state    (read_state)
    );
   
    // store read address
    always_ff @(posedge clk) begin
        if (read_state == 1'b0) begin
            read_addr_reg <= araddr;
        end
    end
    
    // instantiate a BRAM to support readback
    logic [ADDR_WIDTH - 1 : 0] addrb;

    assign addrb = update_valid ? update_addr[ADDR_WIDTH - 1 : 0] : read_addr[ADDR_WIDTH - 1 : 0];

    rams_tdp_rf_rf #(
        .WIDTH (WIDTH),
        .DEPTH (DEPTH)
    )
    u_true_dual_port_cache
    ( 
        .clka  (clk                             ),
        .clkb  (clk                             ),
        .ena   (1'b1                            ),
        .enb   (1'b1                            ),
        .wea   (write_en                        ),
        .web   (update_valid                    ),
        .addra (write_addr[ADDR_WIDTH - 1 : 0]  ),
        .addrb (addrb                           ),
        .dia   (write_data                      ),
        .dib   (update_data                     ),
        .doa   (                                ),
        .dob   (rdata                           )
    );

endmodule
