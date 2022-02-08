module fpga_logic #(
    parameter TARGET = "GENERIC",		// For correct simulation! Override by "LATTICE" from parent module!!!
    parameter USE_CLK90 = "TRUE",               // For correct simulation! Override by "FALSE" from parent module!!!
    parameter DCHP_TEMPLATE_EEPROM_ADDR = 24'h1ff000
)
(
    input              clk,
    input              rst,
    input              clk90,

    output reg         dbg_led,

    output             spi_flash_sck,
    output             spi_flash_mosi,
    input              spi_flash_miso,    
    output             spi_flash_cs,

    /*
     * AXI output
     */
    output  wire [7:0]  tx_axis_tdata,
    output  wire [1:0]  tx_axis_tkeep,
    output  wire        tx_axis_tvalid,
    input wire          tx_axis_tready,
    output  wire        tx_axis_tlast,
    output  wire        tx_axis_tuser,

    /*
     * AXI input
     */
    input wire [7:0]  rx_axis_tdata,
    input wire [1:0]  rx_axis_tkeep,
    input wire        rx_axis_tvalid,
    output wire       rx_axis_tready,
    input wire        rx_axis_tlast,
    input wire        rx_axis_tuser

);


// Ethernet frame between Ethernet modules and UDP stack
wire rx_eth_hdr_ready;
wire rx_eth_hdr_valid;
wire [47:0] rx_eth_dest_mac;
wire [47:0] rx_eth_src_mac;
wire [15:0] rx_eth_type;
wire [7:0] rx_eth_payload_axis_tdata;
wire rx_eth_payload_axis_tvalid;
wire rx_eth_payload_axis_tready;
wire rx_eth_payload_axis_tlast;
wire rx_eth_payload_axis_tuser;

wire tx_eth_hdr_ready;
wire tx_eth_hdr_valid;
wire [47:0] tx_eth_dest_mac;
wire [47:0] tx_eth_src_mac;
wire [15:0] tx_eth_type;
wire [7:0] tx_eth_payload_axis_tdata;
wire tx_eth_payload_axis_tvalid;
wire tx_eth_payload_axis_tready;
wire tx_eth_payload_axis_tlast;
wire tx_eth_payload_axis_tuser;

// IP frame connections
wire rx_ip_hdr_valid;
wire rx_ip_hdr_ready;
wire [47:0] rx_ip_eth_dest_mac;
wire [47:0] rx_ip_eth_src_mac;
wire [15:0] rx_ip_eth_type;
wire [3:0] rx_ip_version;
wire [3:0] rx_ip_ihl;
wire [5:0] rx_ip_dscp;
wire [1:0] rx_ip_ecn;
wire [15:0] rx_ip_length;
wire [15:0] rx_ip_identification;
wire [2:0] rx_ip_flags;
wire [12:0] rx_ip_fragment_offset;
wire [7:0] rx_ip_ttl;
wire [7:0] rx_ip_protocol;
wire [15:0] rx_ip_header_checksum;
wire [31:0] rx_ip_source_ip;
wire [31:0] rx_ip_dest_ip;
wire [7:0] rx_ip_payload_axis_tdata;
wire rx_ip_payload_axis_tvalid;
wire rx_ip_payload_axis_tready;
wire rx_ip_payload_axis_tlast;
wire rx_ip_payload_axis_tuser;

wire tx_ip_hdr_valid;
wire tx_ip_hdr_ready;
wire [5:0] tx_ip_dscp;
wire [1:0] tx_ip_ecn;
wire [15:0] tx_ip_length;
wire [7:0] tx_ip_ttl;
wire [7:0] tx_ip_protocol;
wire [31:0] tx_ip_source_ip;
wire [31:0] tx_ip_dest_ip;
wire [7:0] tx_ip_payload_axis_tdata;
wire tx_ip_payload_axis_tvalid;
wire tx_ip_payload_axis_tready;
wire tx_ip_payload_axis_tlast;
wire tx_ip_payload_axis_tuser;

// UDP frame connections
wire rx_udp_hdr_valid;
reg  rx_udp_hdr_ready;
wire [47:0] rx_udp_eth_dest_mac;
wire [47:0] rx_udp_eth_src_mac;
wire [15:0] rx_udp_eth_type;
wire [3:0] rx_udp_ip_version;
wire [3:0] rx_udp_ip_ihl;
wire [5:0] rx_udp_ip_dscp;
wire [1:0] rx_udp_ip_ecn;
wire [15:0] rx_udp_ip_length;
wire [15:0] rx_udp_ip_identification;
wire [2:0] rx_udp_ip_flags;
wire [12:0] rx_udp_ip_fragment_offset;
wire [7:0] rx_udp_ip_ttl;
wire [7:0] rx_udp_ip_protocol;
wire [15:0] rx_udp_ip_header_checksum;
wire [31:0] rx_udp_ip_source_ip;
wire [31:0] rx_udp_ip_dest_ip;
wire [15:0] rx_udp_source_port;
wire [15:0] rx_udp_dest_port;
wire [15:0] rx_udp_length;
wire [15:0] rx_udp_checksum;
wire [7:0] rx_udp_payload_axis_tdata;
wire rx_udp_payload_axis_tvalid;
reg rx_udp_payload_axis_tready;
wire rx_udp_payload_axis_tlast;
wire rx_udp_payload_axis_tuser;

wire [5:0] tx_udp_ip_dscp;
wire [1:0] tx_udp_ip_ecn;
wire [7:0] tx_udp_ip_ttl;
wire [15:0] tx_udp_checksum;

reg        tx_udp_hdr_valid;
wire        tx_udp_hdr_ready;
reg [31:0] tx_udp_ip_source_ip;
reg [31:0] tx_udp_ip_dest_ip;
reg [15:0] tx_udp_source_port;
reg [15:0] tx_udp_dest_port;
reg [15:0] tx_udp_length;

wire [7:0] tx_udp_payload_axis_tdata;
wire tx_udp_payload_axis_tvalid;
wire tx_udp_payload_axis_tready;
wire tx_udp_payload_axis_tlast;
wire tx_udp_payload_axis_tuser;

wire [7:0] rx_fifo_udp_payload_axis_tdata;
wire rx_fifo_udp_payload_axis_tvalid;
wire rx_fifo_udp_payload_axis_tready;
wire rx_fifo_udp_payload_axis_tlast;
wire rx_fifo_udp_payload_axis_tuser;

wire [7:0] tx_fifo_udp_payload_axis_tdata;
wire tx_fifo_udp_payload_axis_tvalid;
wire tx_fifo_udp_payload_axis_tready;
wire tx_fifo_udp_payload_axis_tlast;
wire tx_fifo_udp_payload_axis_tuser;

wire udp_tx_busy;

// Configuration
wire [47:0] local_mac   = 48'h02_00_00_00_00_00;
wire [31:0] local_ip    = {8'd192, 8'd168, 8'd2,   8'd128};
wire [31:0] gateway_ip  = {8'd192, 8'd168, 8'd2,   8'd1};
wire [31:0] subnet_mask = {8'd255, 8'd255, 8'd255, 8'd0};

// Loop back UDP
wire match_cond = rx_udp_dest_port == 1234;
wire no_match = !match_cond;

reg match_cond_reg = 0;
reg no_match_reg = 0;

always @(posedge clk) begin
    if (rst) begin
        match_cond_reg <= 0;
        no_match_reg <= 0;
    end else begin
        if (rx_udp_payload_axis_tvalid) begin
            if ((!match_cond_reg && !no_match_reg) ||
                (rx_udp_payload_axis_tvalid && rx_udp_payload_axis_tready && rx_udp_payload_axis_tlast)) begin
                match_cond_reg <= match_cond;
                no_match_reg <= no_match;
            end
        end else begin
            match_cond_reg <= 0;
            no_match_reg <= 0;
        end
    end
end

assign tx_udp_ip_dscp = 0;
assign tx_udp_ip_ecn = 0;
assign tx_udp_ip_ttl = 64;
assign tx_udp_checksum = 0;

assign tx_udp_payload_axis_tdata = tx_fifo_udp_payload_axis_tdata;
assign tx_udp_payload_axis_tvalid = tx_fifo_udp_payload_axis_tvalid;
assign tx_fifo_udp_payload_axis_tready = tx_udp_payload_axis_tready;
assign tx_udp_payload_axis_tlast = tx_fifo_udp_payload_axis_tlast;
assign tx_udp_payload_axis_tuser = tx_fifo_udp_payload_axis_tuser;

assign rx_fifo_udp_payload_axis_tdata = rx_udp_payload_axis_tdata;
assign rx_fifo_udp_payload_axis_tvalid = rx_udp_payload_axis_tvalid && match_cond_reg;
//assign rx_udp_payload_axis_tready = (rx_fifo_udp_payload_axis_tready && match_cond_reg) || no_match_reg;
assign rx_fifo_udp_payload_axis_tlast = rx_udp_payload_axis_tlast;
assign rx_fifo_udp_payload_axis_tuser = rx_udp_payload_axis_tuser;

eth_axis_rx
eth_axis_rx_inst (
    .clk(clk),
    .rst(rst),
    // AXI input
    .s_axis_tdata(rx_axis_tdata),
    .s_axis_tvalid(rx_axis_tvalid),
    .s_axis_tready(rx_axis_tready),
    .s_axis_tlast(rx_axis_tlast),
    .s_axis_tuser(rx_axis_tuser),
    // Ethernet frame output
    .m_eth_hdr_valid(rx_eth_hdr_valid),
    .m_eth_hdr_ready(rx_eth_hdr_ready),
    .m_eth_dest_mac(rx_eth_dest_mac),
    .m_eth_src_mac(rx_eth_src_mac),
    .m_eth_type(rx_eth_type),
    .m_eth_payload_axis_tdata(rx_eth_payload_axis_tdata),
    .m_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(rx_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(rx_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(rx_eth_payload_axis_tuser),
    // Status signals
    .busy(),
    .error_header_early_termination()
);

eth_axis_tx
eth_axis_tx_inst (
    .clk(clk),
    .rst(rst),
    // Ethernet frame input
    .s_eth_hdr_valid(tx_eth_hdr_valid),
    .s_eth_hdr_ready(tx_eth_hdr_ready),
    .s_eth_dest_mac(tx_eth_dest_mac),
    .s_eth_src_mac(tx_eth_src_mac),
    .s_eth_type(tx_eth_type),
    .s_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
    .s_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
    .s_eth_payload_axis_tready(tx_eth_payload_axis_tready),
    .s_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
    .s_eth_payload_axis_tuser(tx_eth_payload_axis_tuser),
    // AXI output
    .m_axis_tdata(tx_axis_tdata),
    .m_axis_tvalid(tx_axis_tvalid),
    .m_axis_tready(tx_axis_tready),
    .m_axis_tlast(tx_axis_tlast),
    .m_axis_tuser(tx_axis_tuser),
    // Status signals
    .busy()
);
  


udp_complete #(
    .UDP_CHECKSUM_GEN_ENABLE (0)
)
udp_complete_inst (
    .clk(clk),
    .rst(rst),
    // Ethernet frame input
    .s_eth_hdr_valid(rx_eth_hdr_valid),
    .s_eth_hdr_ready(rx_eth_hdr_ready),
    .s_eth_dest_mac(rx_eth_dest_mac),
    .s_eth_src_mac(rx_eth_src_mac),
    .s_eth_type(rx_eth_type),
    .s_eth_payload_axis_tdata(rx_eth_payload_axis_tdata),
    .s_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid),
    .s_eth_payload_axis_tready(rx_eth_payload_axis_tready),
    .s_eth_payload_axis_tlast(rx_eth_payload_axis_tlast),
    .s_eth_payload_axis_tuser(rx_eth_payload_axis_tuser),
    // Ethernet frame output
    .m_eth_hdr_valid(tx_eth_hdr_valid),
    .m_eth_hdr_ready(tx_eth_hdr_ready),
    .m_eth_dest_mac(tx_eth_dest_mac),
    .m_eth_src_mac(tx_eth_src_mac),
    .m_eth_type(tx_eth_type),
    .m_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
    .m_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(tx_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(tx_eth_payload_axis_tuser),
    // IP frame input
    .s_ip_hdr_valid(tx_ip_hdr_valid),
    .s_ip_hdr_ready(tx_ip_hdr_ready),
    .s_ip_dscp(tx_ip_dscp),
    .s_ip_ecn(tx_ip_ecn),
    .s_ip_length(tx_ip_length),
    .s_ip_ttl(tx_ip_ttl),
    .s_ip_protocol(tx_ip_protocol),
    .s_ip_source_ip(tx_ip_source_ip),
    .s_ip_dest_ip(tx_ip_dest_ip),
    .s_ip_payload_axis_tdata(tx_ip_payload_axis_tdata),
    .s_ip_payload_axis_tvalid(tx_ip_payload_axis_tvalid),
    .s_ip_payload_axis_tready(tx_ip_payload_axis_tready),
    .s_ip_payload_axis_tlast(tx_ip_payload_axis_tlast),
    .s_ip_payload_axis_tuser(tx_ip_payload_axis_tuser),
    // IP frame output
    .m_ip_hdr_valid(rx_ip_hdr_valid),
    .m_ip_hdr_ready(rx_ip_hdr_ready),
    .m_ip_eth_dest_mac(rx_ip_eth_dest_mac),
    .m_ip_eth_src_mac(rx_ip_eth_src_mac),
    .m_ip_eth_type(rx_ip_eth_type),
    .m_ip_version(rx_ip_version),
    .m_ip_ihl(rx_ip_ihl),
    .m_ip_dscp(rx_ip_dscp),
    .m_ip_ecn(rx_ip_ecn),
    .m_ip_length(rx_ip_length),
    .m_ip_identification(rx_ip_identification),
    .m_ip_flags(rx_ip_flags),
    .m_ip_fragment_offset(rx_ip_fragment_offset),
    .m_ip_ttl(rx_ip_ttl),
    .m_ip_protocol(rx_ip_protocol),
    .m_ip_header_checksum(rx_ip_header_checksum),
    .m_ip_source_ip(rx_ip_source_ip),
    .m_ip_dest_ip(rx_ip_dest_ip),
    .m_ip_payload_axis_tdata(rx_ip_payload_axis_tdata),
    .m_ip_payload_axis_tvalid(rx_ip_payload_axis_tvalid),
    .m_ip_payload_axis_tready(rx_ip_payload_axis_tready),
    .m_ip_payload_axis_tlast(rx_ip_payload_axis_tlast),
    .m_ip_payload_axis_tuser(rx_ip_payload_axis_tuser),
    // UDP frame input
    .s_udp_hdr_valid(tx_udp_hdr_valid),
    .s_udp_hdr_ready(tx_udp_hdr_ready),
    .s_udp_ip_dscp(tx_udp_ip_dscp),
    .s_udp_ip_ecn(tx_udp_ip_ecn),
    .s_udp_ip_ttl(tx_udp_ip_ttl),
    .s_udp_ip_source_ip(tx_udp_ip_source_ip),
    .s_udp_ip_dest_ip(tx_udp_ip_dest_ip),
    .s_udp_source_port(tx_udp_source_port),
    .s_udp_dest_port(tx_udp_dest_port),
    .s_udp_length(tx_udp_length),
    .s_udp_checksum(tx_udp_checksum),
    .s_udp_payload_axis_tdata(tx_udp_payload_axis_tdata),
    .s_udp_payload_axis_tvalid(tx_udp_payload_axis_tvalid),
    .s_udp_payload_axis_tready(tx_udp_payload_axis_tready),
    .s_udp_payload_axis_tlast(tx_udp_payload_axis_tlast),
    .s_udp_payload_axis_tuser(tx_udp_payload_axis_tuser),
    // UDP frame output
    .m_udp_hdr_valid(rx_udp_hdr_valid),
    .m_udp_hdr_ready(rx_udp_hdr_ready),
    .m_udp_eth_dest_mac(rx_udp_eth_dest_mac),
    .m_udp_eth_src_mac(rx_udp_eth_src_mac),
    .m_udp_eth_type(rx_udp_eth_type),
    .m_udp_ip_version(rx_udp_ip_version),
    .m_udp_ip_ihl(rx_udp_ip_ihl),
    .m_udp_ip_dscp(rx_udp_ip_dscp),
    .m_udp_ip_ecn(rx_udp_ip_ecn),
    .m_udp_ip_length(rx_udp_ip_length),
    .m_udp_ip_identification(rx_udp_ip_identification),
    .m_udp_ip_flags(rx_udp_ip_flags),
    .m_udp_ip_fragment_offset(rx_udp_ip_fragment_offset),
    .m_udp_ip_ttl(rx_udp_ip_ttl),
    .m_udp_ip_protocol(rx_udp_ip_protocol),
    .m_udp_ip_header_checksum(rx_udp_ip_header_checksum),
    .m_udp_ip_source_ip(rx_udp_ip_source_ip),
    .m_udp_ip_dest_ip(rx_udp_ip_dest_ip),
    .m_udp_source_port(rx_udp_source_port),
    .m_udp_dest_port(rx_udp_dest_port),
    .m_udp_length(rx_udp_length),
    .m_udp_checksum(rx_udp_checksum),
    .m_udp_payload_axis_tdata(rx_udp_payload_axis_tdata),
    .m_udp_payload_axis_tvalid(rx_udp_payload_axis_tvalid),
    .m_udp_payload_axis_tready(rx_udp_payload_axis_tready),
    .m_udp_payload_axis_tlast(rx_udp_payload_axis_tlast),
    .m_udp_payload_axis_tuser(rx_udp_payload_axis_tuser),
    // Status signals
    .ip_rx_busy(),
    .ip_tx_busy(),
    .udp_rx_busy(),
    .udp_tx_busy(udp_tx_busy),
    .ip_rx_error_header_early_termination(),
    .ip_rx_error_payload_early_termination(),
    .ip_rx_error_invalid_header(),
    .ip_rx_error_invalid_checksum(),
    .ip_tx_error_payload_early_termination(),
    .ip_tx_error_arp_failed(),
    .udp_rx_error_header_early_termination(),
    .udp_rx_error_payload_early_termination(),
    .udp_tx_error_payload_early_termination(),
    // Configuration
    .local_mac(local_mac),
    .local_ip(local_ip),
    .gateway_ip(gateway_ip),
    .subnet_mask(subnet_mask),
    .clear_arp_cache(0)
);



// AXI Stream for read EEPROM Data
reg  rst_eeprom;
reg [23:0] spi_start_addr;

wire [7:0] spi_m_tdata;
wire spi_m_tvalid;
reg spi_m_tready; 

reg [7:0] spi_s_tdata;
reg spi_s_tvalid;
wire spi_s_tready; 

reg spi_read_strobe;
reg spi_write_strobe;
reg spi_erase_strobe;

wire spi_fsm_in_finished;

SpiFlashReader flashReader
(
   .rst (rst_eeprom),     
   .clk (clk),     

   .read_strobe(spi_read_strobe),
   .write_strobe(spi_write_strobe),
   .erase_strobe(spi_erase_strobe),
   .start_addr(spi_start_addr),
         
   .spi_sck(spi_flash_sck), 
   .spi_mosi(spi_flash_mosi),
   .spi_miso(spi_flash_miso),
   .spi_cs(spi_flash_cs),  
         
   .m_tdata(spi_m_tdata), 
   .m_tvalid(spi_m_tvalid),
   .m_tready(spi_m_tready),

   .s_tdata(spi_s_tdata), 
   .s_tvalid(spi_s_tvalid),
   .s_tready(spi_s_tready),

   .finished (spi_fsm_in_finished) 
);



reg [7:0] ourData_tdata;
reg       ourData_tvalid;
wire      ourData_tready;
reg       ourData_tlast;

reg [7:0] eeprom_cnt;

enum {idle,
       pre_reflect_1,pre_reflect_2,reflect_1,reflect_2,
       rd_eeprom_addr0,rd_eeprom_addr1,rd_eeprom_addr2,
       rd_eeprom_process,rd_eeprom_send1,rd_eeprom_send2,
       wr_eeprom_addr0,wr_eeprom_addr1,wr_eeprom_addr2,
       wr_eeprom_process1,wr_eeprom_process2,wr_eeprom_process3,
       er_eeprom_addr0,er_eeprom_addr1,er_eeprom_addr2,
       er_eeprom_process1,er_eeprom_process2,
       dhcp_fill_0
     } answerState;

always @(posedge clk)
begin
    if (rst)
    begin
        rst_eeprom <= 1;
        spi_m_tready <= 0;
        answerState <= idle;
        rx_udp_hdr_ready <= 1;
        rx_udp_payload_axis_tready <= 1;
        ourData_tvalid <= 0;
        ourData_tlast <= 0;
        tx_udp_hdr_valid <= 0;
        dbg_led <= 1;
        spi_read_strobe <= 0;
        spi_write_strobe <= 0;
        spi_erase_strobe <= 0;
    end else
    begin
        case (answerState)
        idle: begin
               dbg_led <= 1; 
               spi_read_strobe <= 0;
               spi_write_strobe <= 0;
               spi_erase_strobe <= 0;
               rst_eeprom <= 0;
               spi_m_tready <= 0;
               rx_udp_hdr_ready <= 1;
               ourData_tvalid <= 0;
               ourData_tlast <= 0;
               tx_udp_hdr_valid <= 0;
               rx_udp_payload_axis_tready <= 1;
               if (rx_udp_hdr_valid) 
               begin
                  case (rx_udp_dest_port)
                     // Reflect port (just for test purposes)
                     1234: begin
                         tx_udp_ip_source_ip <= local_ip;
                         tx_udp_ip_dest_ip <= rx_udp_ip_source_ip;  
                         tx_udp_source_port <= 1234; 
                         tx_udp_dest_port <= rx_udp_source_port;   
                         tx_udp_length <= rx_udp_length;
                         rx_udp_hdr_ready <= 0;
                         answerState <= pre_reflect_1;
                     end
                     16'hD0C0: begin
                         rx_udp_hdr_ready <= 0;
                         // DHCP Temp
                         spi_start_addr<=DCHP_TEMPLATE_EEPROM_ADDR;
                         eeprom_cnt <= 8'hf7;      // Request for read 0xf8 bytes
                         spi_read_strobe <= 1;     // Start read from EEPROM

                         tx_udp_ip_source_ip <= 32'h00000000;
                         tx_udp_ip_dest_ip <= 32'hffffffff; 
                         tx_udp_source_port <= 16'd68; 
                         tx_udp_dest_port <= 16'd67;   

                         spi_m_tready <= 1;
                         answerState <= dhcp_fill_0;
                     end
                     // Read EEPROM Port (0xEEE0)
                     16'heee0: begin
                         rx_udp_hdr_ready <= 0;
                         tx_udp_ip_source_ip <= local_ip;
                         tx_udp_ip_dest_ip <= rx_udp_ip_source_ip;  
                         tx_udp_source_port <= 16'heee0; 
                         tx_udp_dest_port <= 16'heee1;   
                         tx_udp_length <= 128 + 8;   			 // Always sending 128 bytes
                         answerState <= rd_eeprom_addr0;
                     end
                     // Write EEPROM
                     16'heee2: begin
                         rx_udp_hdr_ready <= 0;
                         answerState <= wr_eeprom_addr0;
                     end
                     // Erase EEPROM
                     16'heeee: begin
                         rx_udp_hdr_ready <= 0;
                         answerState <= er_eeprom_addr0;
                     end
                  endcase
               end
        end
        pre_reflect_1: begin
              answerState <= pre_reflect_2;
        end
        pre_reflect_2: begin
              tx_udp_hdr_valid <= 1;
              if (tx_udp_hdr_ready)
              begin
                  answerState <= reflect_2;
              end
              else
              begin
                  answerState <= reflect_1;
              end
        end
        reflect_1: begin
           if (tx_udp_hdr_ready)
              answerState <= reflect_2;
        end
        reflect_2: begin
           tx_udp_hdr_valid <= 0;
           ourData_tdata <= rx_udp_payload_axis_tdata;
           ourData_tvalid <= rx_udp_payload_axis_tvalid;
           ourData_tlast <= rx_udp_payload_axis_tlast;
           if (rx_udp_payload_axis_tvalid & rx_udp_payload_axis_tlast)
           begin
               answerState <= idle; 
           end
        end
        rd_eeprom_addr0: begin
           spi_m_tready <= 1;
           if (rx_udp_payload_axis_tvalid)
           begin
              spi_start_addr [23:0] <= {rx_udp_payload_axis_tdata,spi_start_addr [23:8]};
              answerState <= rd_eeprom_addr1;
           end
        end
        rd_eeprom_addr1: begin
           if (rx_udp_payload_axis_tvalid)
           begin
              spi_start_addr [23:0] <= {rx_udp_payload_axis_tdata,spi_start_addr [23:8]};
              answerState <= rd_eeprom_addr2;
           end
        end
        rd_eeprom_addr2: begin
           if (rx_udp_payload_axis_tvalid)
           begin
              spi_start_addr [23:0] <= {rx_udp_payload_axis_tdata,spi_start_addr [23:8]};
	      spi_read_strobe <= 1;
              eeprom_cnt <= 8'd127;	// For read 128 bytes
              answerState <= rd_eeprom_process;
           end
        end
        rd_eeprom_process: begin
           ourData_tdata <= spi_m_tdata;
           ourData_tvalid <= spi_m_tvalid;
           if (spi_m_tvalid)
           begin
               if (eeprom_cnt == 0)
               begin
                   answerState <= idle;//rd_eeprom_send1; 
                   ourData_tlast <= 1;
	           spi_m_tready <= 0;
                   tx_udp_hdr_valid <= 1;		// Start send to UDP

               end else
               begin
                   eeprom_cnt <= eeprom_cnt - 1;
                   ourData_tlast <= 0;
               end
           end
        end
        rd_eeprom_send1: begin
               if (udp_tx_busy)
               begin
                   answerState <= rd_eeprom_send2; 
               end
        end
        rd_eeprom_send2: begin
               if (!udp_tx_busy)
               begin
                   answerState <= idle; 
               end
        end
        wr_eeprom_addr0: begin
           if (rx_udp_payload_axis_tvalid)
           begin
              spi_start_addr [23:0] <= {rx_udp_payload_axis_tdata,spi_start_addr [23:8]};
              answerState <= wr_eeprom_addr1;
           end
        end
        wr_eeprom_addr1: begin
           if (rx_udp_payload_axis_tvalid)
           begin
              spi_start_addr [23:0] <= {rx_udp_payload_axis_tdata,spi_start_addr [23:8]};
              answerState <= wr_eeprom_addr2;
           end
        end
        wr_eeprom_addr2: begin
           if (rx_udp_payload_axis_tvalid)
           begin
              spi_start_addr [23:0] <= {rx_udp_payload_axis_tdata,spi_start_addr [23:8]};
	      spi_write_strobe <= 1;
              spi_s_tvalid <= 0;
              rx_udp_payload_axis_tready <= 0;
              answerState <= wr_eeprom_process1;
           end
        end
        wr_eeprom_process1: begin
            if (rx_udp_payload_axis_tvalid)
            begin
                spi_s_tdata <= rx_udp_payload_axis_tdata;
                spi_s_tvalid <= 1;
                rx_udp_payload_axis_tready <= 1;
                answerState <= wr_eeprom_process2;
            end else
            begin
                answerState <= wr_eeprom_process3; 
                spi_s_tvalid <= 0;
            end
        end
        wr_eeprom_process2: begin
            rx_udp_payload_axis_tready <= 0;
            if (spi_s_tready)
            begin
                spi_s_tvalid <= 0;
                answerState <= wr_eeprom_process1;
            end
        end
        wr_eeprom_process3: begin
              if (spi_flash_cs)
              begin
                answerState <= idle; 
             end
        end
        er_eeprom_addr0: begin
           if (rx_udp_payload_axis_tvalid)
           begin
              spi_start_addr [23:0] <= {rx_udp_payload_axis_tdata,spi_start_addr [23:8]};
              answerState <= er_eeprom_addr1;
           end
        end
        er_eeprom_addr1: begin
           if (rx_udp_payload_axis_tvalid)
           begin
              spi_start_addr [23:0] <= {rx_udp_payload_axis_tdata,spi_start_addr [23:8]};
              answerState <= er_eeprom_addr2;
           end
        end
        er_eeprom_addr2: begin
           if (rx_udp_payload_axis_tvalid)
           begin
              spi_start_addr [23:0] <= {rx_udp_payload_axis_tdata,spi_start_addr [23:8]};
	      spi_erase_strobe <= 1;
              spi_s_tvalid <= 0;
              answerState <= er_eeprom_process1;
           end
        end
        er_eeprom_process1: begin
            if (spi_fsm_in_finished)
            begin
                answerState <= idle; 
            end
        end
        dhcp_fill_0: begin
           ourData_tdata <= spi_m_tdata;
           ourData_tvalid <= spi_m_tvalid;
           if (spi_m_tvalid)
           begin
               if (eeprom_cnt == 0)
               begin
                   answerState <= idle;
                   ourData_tlast <= 1;
	           spi_m_tready <= 0;
                   tx_udp_length <= 16'h00f8 + 8;   	
                   tx_udp_hdr_valid <= 1;		// Start send to UDP
               end else
               begin
                   eeprom_cnt <= eeprom_cnt - 1;
                   ourData_tlast <= 0;
               end
           end
        end
        endcase

    end 
end



axis_fifo #(
    .DEPTH(8192),
    .DATA_WIDTH(8),
    .KEEP_ENABLE(0),
    .ID_ENABLE(0),
    .DEST_ENABLE(0),
    .USER_ENABLE(1),
    .USER_WIDTH(1),
    .FRAME_FIFO(0)
)
udp_payload_fifo (
    .clk(clk),
    .rst(rst),
    // AXI input
    .s_axis_tdata(ourData_tdata/*rx_fifo_udp_payload_axis_tdata/*+8'h01*/),
    .s_axis_tkeep(0),
    .s_axis_tvalid(ourData_tvalid/*rx_fifo_udp_payload_axis_tvalid*/),
    .s_axis_tready(ourData_tready/*rx_fifo_udp_payload_axis_tready*/),
    .s_axis_tlast(ourData_tlast/*rx_fifo_udp_payload_axis_tlast*/),
    .s_axis_tid(0),
    .s_axis_tdest(0),
    .s_axis_tuser(rx_fifo_udp_payload_axis_tuser),
    // AXI output
    .m_axis_tdata(tx_fifo_udp_payload_axis_tdata),
    .m_axis_tkeep(),
    .m_axis_tvalid(tx_fifo_udp_payload_axis_tvalid),
    .m_axis_tready(tx_fifo_udp_payload_axis_tready),
    .m_axis_tlast(tx_fifo_udp_payload_axis_tlast),
    .m_axis_tid(),
    .m_axis_tdest(),
    .m_axis_tuser(tx_fifo_udp_payload_axis_tuser),
    // Status
    .status_overflow(),
    .status_bad_frame(),
    .status_good_frame()
);


icmp ICMP (
    .clk(clk),
    .rst(rst),
    // 
    .m_ip_hdr_valid(tx_ip_hdr_valid),
    .m_ip_hdr_ready(tx_ip_hdr_ready),
    .m_ip_dscp(tx_ip_dscp),
    .m_ip_ecn(tx_ip_ecn),
    .m_ip_length(tx_ip_length),
    .m_ip_ttl(tx_ip_ttl),
    .m_ip_protocol(tx_ip_protocol),
    .m_ip_source_ip(tx_ip_source_ip),
    .m_ip_dest_ip(tx_ip_dest_ip),
    .m_ip_payload_axis_tdata(tx_ip_payload_axis_tdata),
    .m_ip_payload_axis_tvalid(tx_ip_payload_axis_tvalid),
    .m_ip_payload_axis_tready(tx_ip_payload_axis_tready),
    .m_ip_payload_axis_tlast(tx_ip_payload_axis_tlast),
    .m_ip_payload_axis_tuser(tx_ip_payload_axis_tuser),
    // 
    .s_ip_hdr_valid(rx_ip_hdr_valid),
    .s_ip_hdr_ready(rx_ip_hdr_ready),
    .s_ip_eth_type(rx_ip_eth_type),
    .s_ip_version(rx_ip_version),
    .s_ip_ihl(rx_ip_ihl),
    .s_ip_dscp(rx_ip_dscp),
    .s_ip_ecn(rx_ip_ecn),
    .s_ip_length(rx_ip_length),
    .s_ip_ttl(rx_ip_ttl),
    .s_ip_protocol(rx_ip_protocol),
    .s_ip_source_ip(rx_ip_source_ip),
    .s_ip_dest_ip(rx_ip_dest_ip),
    .s_ip_payload_axis_tdata(rx_ip_payload_axis_tdata),
    .s_ip_payload_axis_tvalid(rx_ip_payload_axis_tvalid),
    .s_ip_payload_axis_tready(rx_ip_payload_axis_tready),
    .s_ip_payload_axis_tlast(rx_ip_payload_axis_tlast),
    .s_ip_payload_axis_tuser(rx_ip_payload_axis_tuser),

    .local_ip(local_ip)
);

endmodule
