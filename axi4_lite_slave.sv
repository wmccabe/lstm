module axi4_lite_slave
(
    input  logic          clk,
    input  logic          rst,
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
    input  logic          rready
);

    typedef enum logic [2 : 0] {IDLE, RESPOND} state_t;
    
    // write address logic
    logic [31 : 0] write_addr;
    logic [31 : 0] write_addr_reg;
    logic write_en;
    
    assign awready    = !rst;
    assign write_addr = (awvalid && awready) ? awaddr : write_addr_reg;
    assign write_en = wvalid && wready;
    assign bresp = 2'b00;
 
    always_ff @(posedge clk) begin
        if (awready && awvalid) begin
            write_addr_reg <= awaddr;
        end
    end
    
    // write data logic
    logic write_state;
    assign wready = !rst && (write_state == 1'b0);
   
    axi_handshake 
    u_write_handshake (
        .clk      (clk        ),
        .rst      (rst        ),
        .m_valid  (wvalid     ),
        .s_valid  (bvalid     ),
        .m_ready  (bready     ),
        .state    (write_state)
    );
 
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
        if (read_state == IDLE) begin
            read_addr_reg <= araddr;
        end
    end
    
    // instantiate a BRAM to support readback
    simple_dual_one_clock #(
        .WIDTH (32  ),
        .DEPTH (256 ) 
    )
    u_simple_dual_cache
    (
        .clk   (clk              ),
        .ena   (1'b1             ),
        .enb   (1'b1             ),
        .wea   (write_en         ),
        .addra (write_addr       ),
        .addrb (read_addr        ),
        .dia   (wdata            ),
        .dob   (rdata            )
    );

endmodule
