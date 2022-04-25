module fpga_logic #(
    parameter TARGET = "GENERIC",		// For correct simulation! Override by "LATTICE" from parent module!!!
    parameter USE_CLK90 = "TRUE",               // For correct simulation! Override by "FALSE" from parent module!!!
//    parameter DCHP_TEMPLATE_EEPROM_ADDR = 24'h1ff000
    parameter DEFAULT_IP_EPROM_ADDR = 24'h1ff000
)
(
    input              clk,
    input              clk50,
    input              rst,
    input              clk90,

    input              rxd,                       // It is uses as "Start DHCP" trigger

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
    input wire        rx_axis_tuser,

    output [15:0]            dbg_out

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
wire [47:0] local_mac;//   = 48'h02_00_00_00_00_00;
wire [31:0] local_ip;//    = {8'd192, 8'd168, 8'd2,   8'd128};
wire [31:0] gateway_ip; //  = {8'd192, 8'd168, 8'd2,   8'd1};
wire [31:0] subnet_mask;// = {8'd255, 8'd255, 8'd255, 8'd0};

// Loop back UDP
wire match_cond = rx_udp_dest_port == 1234;
wire no_match = !match_cond;

reg [11:0] mac_matched_1;
reg [2:0] mac_matched_2;
reg  mac_matched;
reg mac_is_broadcast [3:0];
reg mac_is_broadcast2;

reg clear_arp_cache;
wire arp_cache_ready;


always @ (posedge clk)
begin
/*     mac_is_broadcast [3] <= rx_eth_dest_mac [47:36] == 12'b111111111111;
     mac_is_broadcast [2] <= rx_eth_dest_mac [35:24] == 12'b111111111111;
     mac_is_broadcast [1] <= rx_eth_dest_mac [23:12] == 12'b111111111111;
     mac_is_broadcast [0] <= rx_eth_dest_mac [11:0] == 12'b111111111111; */
     mac_is_broadcast [3] <= rx_eth_dest_mac [47] & rx_eth_dest_mac [46] & rx_eth_dest_mac [45] & rx_eth_dest_mac [44] & 
                             rx_eth_dest_mac [43] & rx_eth_dest_mac [42] & rx_eth_dest_mac [41] & rx_eth_dest_mac [40] & 
                             rx_eth_dest_mac [39] & rx_eth_dest_mac [38] & rx_eth_dest_mac [37] & rx_eth_dest_mac [36];
     mac_is_broadcast [2] <= rx_eth_dest_mac [35] & rx_eth_dest_mac [34] & rx_eth_dest_mac [33] & rx_eth_dest_mac [32] & 
                             rx_eth_dest_mac [31] & rx_eth_dest_mac [30] & rx_eth_dest_mac [29] & rx_eth_dest_mac [28] & 
                             rx_eth_dest_mac [27] & rx_eth_dest_mac [26] & rx_eth_dest_mac [25] & rx_eth_dest_mac [24];
     mac_is_broadcast [1] <= rx_eth_dest_mac [23] & rx_eth_dest_mac [22] & rx_eth_dest_mac [21] & rx_eth_dest_mac [20] & 
                             rx_eth_dest_mac [19] & rx_eth_dest_mac [18] & rx_eth_dest_mac [17] & rx_eth_dest_mac [16] & 
                             rx_eth_dest_mac [15] & rx_eth_dest_mac [14] & rx_eth_dest_mac [13] & rx_eth_dest_mac [12];
     mac_is_broadcast [0] <= rx_eth_dest_mac [11] & rx_eth_dest_mac [10] & rx_eth_dest_mac [9] & rx_eth_dest_mac [8] & 
                             rx_eth_dest_mac [7] & rx_eth_dest_mac [6] & rx_eth_dest_mac [5] & rx_eth_dest_mac [4] & 
                             rx_eth_dest_mac [3] & rx_eth_dest_mac [2] & rx_eth_dest_mac [1] & rx_eth_dest_mac [0];
     mac_is_broadcast2 <= mac_is_broadcast [0] & mac_is_broadcast [1] & mac_is_broadcast [2] & mac_is_broadcast [3];

     mac_matched_1 [0] <= (rx_eth_dest_mac [3:0] == local_mac [3:0])?1:0;
     mac_matched_1 [1] <= (rx_eth_dest_mac [7:4] == local_mac [7:4])?1:0;
     mac_matched_1 [2] <= (rx_eth_dest_mac [11:8] == local_mac [11:8])?1:0;
     mac_matched_1 [3] <= (rx_eth_dest_mac [15:12] == local_mac [15:12])?1:0;
     mac_matched_1 [4] <= (rx_eth_dest_mac [19:16] == local_mac [19:16])?1:0;
     mac_matched_1 [5] <= (rx_eth_dest_mac [23:20] == local_mac [23:20])?1:0;
     mac_matched_1 [6] <= (rx_eth_dest_mac [27:24] == local_mac [27:24])?1:0;
     mac_matched_1 [7] <= (rx_eth_dest_mac [31:28] == local_mac [31:28])?1:0;
     mac_matched_1 [8] <= (rx_eth_dest_mac [35:32] == local_mac [35:32])?1:0;
     mac_matched_1 [9] <= (rx_eth_dest_mac [39:36] == local_mac [39:36])?1:0;
     mac_matched_1 [10] <= (rx_eth_dest_mac [43:40] == local_mac [43:40])?1:0;
     mac_matched_1 [11] <= (rx_eth_dest_mac [47:44] == local_mac [47:44])?1:0;
     mac_matched_2 [0] = mac_matched_1 [0] & mac_matched_1 [1] & mac_matched_1 [2] & mac_matched_1 [3];
     mac_matched_2 [1] = mac_matched_1 [4] & mac_matched_1 [5] & mac_matched_1 [6] & mac_matched_1 [7];
     mac_matched_2 [2] = mac_matched_1 [8] & mac_matched_1 [9] & mac_matched_1 [10] & mac_matched_1 [11];

     mac_matched  <= (mac_matched_2 [0] & mac_matched_2 [1] & mac_matched_2 [2]) | mac_is_broadcast2;

end

   wire mac_is_mdns;
   mDNShelper inst_mDNShelper
   (
     .clk (clk),
     .rst (rst),
     .mac (rx_eth_dest_mac),
     .mac_is_mdns (mac_is_mdns)
   );

   reg auto_ip_prepare;
   reg [31:0] auto_ip_ip;
   wire       m_auto_ip_matched;
   reg        auto_ip_matched;
   reg        auto_ip_latch;

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


reg probeMode;
reg probeMode_prev;
wire drop_packet;
reg probePacketIsDropped;
always @(posedge clk)
begin
     if (rst) 
     begin
        probePacketIsDropped <= 0;
        auto_ip_matched <= 0;
        probeMode_prev <= 0;
     end else
     begin
        probeMode_prev <= probeMode;
        if ((probeMode == 1'b1) && (probeMode_prev == 0))
        begin 
           probePacketIsDropped <= 0;   
           auto_ip_matched <= 0;
        end else 
        begin
             if (drop_packet)
             begin
                  probePacketIsDropped <= 1;
             end
             if (m_auto_ip_matched)
             begin
                  auto_ip_matched <= 1;
             end
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

    .m_auto_ip_matched(m_auto_ip_matched),
    // For Auto IP Functionality
    .justProbe(probeMode),
    .drop_packet(drop_packet),

//    .dbg_out(dbg_out),

    // Configuration
    .local_mac(local_mac),
    .local_ip(local_ip),
    .auto_ip_ip(auto_ip_ip),
    .gateway_ip(gateway_ip),
    .subnet_mask(subnet_mask),
    .clear_arp_cache(clear_arp_cache),
    .cache_ready(arp_cache_ready)
);

// AXI Stream for read EEPROM Data
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
   .rst (rst),     
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

reg  dhcp_s_eeprom_process_start;
wire dhcp_s_eeprom_process_finished;

reg  dhcp_m_dhcp_discover_start;
reg  m_dhcp_discover_step_request;
wire dhcp_m_dhcp_discover_finished;

wire [7:0] dhcp_m_dhcp_discover_tdata;
wire  dhcp_m_dhcp_discover_tvalid;
reg  dhcp_m_dhcp_discover_tready;
wire  dhcp_m_dhcp_discover_tlast;

reg             s_dhcp_offer_start;
wire            s_dhcp_offer_finished;
reg   [7:0]     s_dhcp_offer_axis_tdata;
reg             s_dhcp_offer_axis_tvalid;
wire            s_dhcp_offer_axis_tready;
reg             s_dhcp_offer_axis_tlast;

wire            dhcp_offerIsReceived;

DHCPhelper #(
    .TARGET(TARGET)
    )dhcpHelp(
    .clk (clk),
    .clk50 (clk50),
    .rst (rst),

    .s_eeprom_process_start (dhcp_s_eeprom_process_start),
    .s_eeprom_process_finished (dhcp_s_eeprom_process_finished),

    .s_eeprom_axis_tdata (spi_m_tdata), 
    .s_eeprom_axis_tvalid (spi_m_tvalid),
//No need    .s_eeprom_axis_tready

    .m_dhcp_discover_start(dhcp_m_dhcp_discover_start),
    .m_dhcp_discover_finished(dhcp_m_dhcp_discover_finished),
    .m_dhcp_discover_step_request(m_dhcp_discover_step_request),
    .m_dhcp_discover_axis_tdata(dhcp_m_dhcp_discover_tdata),
    .m_dhcp_discover_axis_tvalid(dhcp_m_dhcp_discover_tvalid),
    .m_dhcp_discover_axis_tready(dhcp_m_dhcp_discover_tready),
    .m_dhcp_discover_axis_last(dhcp_m_dhcp_discover_tlast),

    .s_dhcp_offer_start(s_dhcp_offer_start),
    .s_dhcp_offer_finished(s_dhcp_offer_finished),
    .s_dhcp_offer_axis_tdata(s_dhcp_offer_axis_tdata),
    .s_dhcp_offer_axis_tvalid(s_dhcp_offer_axis_tvalid),
    .s_dhcp_offer_axis_tready(s_dhcp_offer_axis_tready),
    .s_dhcp_offer_axis_tlast(s_dhcp_offer_axis_tlast),

    .dhcp_offerIsReceived (dhcp_offerIsReceived),

    .auto_ip_prepare(auto_ip_prepare),
    .auto_ip_latch(auto_ip_latch),
    .auto_ip_ip(auto_ip_ip[15:0]),

//    .dbg_out(dbg_out),


    .local_mac(local_mac),  
    .local_ip(local_ip),   
    .gateway_ip(gateway_ip), 
    .subnet_mask(subnet_mask)
);

wire [31:0] auto_ip_online;
generate
if (TARGET == "GENERIC") 
//if (TARGET == "LATTICE") 
     assign auto_ip_online = 32'h12345678;
else
  prng prng_dhcp_xid_inst (
    .clk (clk),
    .rst (rst),
    .in  (1'b0),
    .res (auto_ip_online)
  );
endgenerate

reg [7:0] ourData_tdata;
reg       ourData_tvalid;
wire      ourData_tready;
reg       ourData_tlast;

reg [7:0] eeprom_cnt;
reg [2:0] addr_cnt;
reg [23:0] eeprom_pwd;

reg string_matched;

typedef enum logic [5:0] {
       idle,
       init_eeprom_1,
       pre_reflect_1,pre_reflect_2,reflect_1,reflect_2,
       rd_eeprom_addr0,
       rd_eeprom_process,//rd_eeprom_send1,rd_eeprom_send2,
       wr_eeprom_addr0,
       wr_eeprom_process1,wr_eeprom_process2,wr_eeprom_process3,
       er_eeprom_addr0,
       er_eeprom_process1,er_eeprom_process2,
       dhcp_start,dhcp_fill_0,dhcp_fill_1,
       dhcp_offer_processing1,dhcp_offer_processing2,
       autoIp_start,autoIp_wait_cache_busy,autoIp_wait_cache_ready,
          autoIp_wait_fake_packet_send,autoIp_wait_fake_packet_sent,
       dbg_string_1,dbg_string_2,
       mDNS_cmp,mDNS_fill_1,mDNS_fill_2,mDNS_fill_3
     } answerStates;

answerStates answerState/* = idle*/;

always @(posedge clk)
begin
    if (rst)
    begin
        dhcp_s_eeprom_process_start <= 0;
        dhcp_m_dhcp_discover_start <= 0;
        s_dhcp_offer_axis_tvalid <= 0;
        s_dhcp_offer_start <= 0;
        spi_m_tready <= 0;
        answerState <= init_eeprom_1;
        rx_udp_hdr_ready <= 1;
        rx_udp_payload_axis_tready <= 1;
        ourData_tvalid <= 0;
        ourData_tlast <= 0;
        tx_udp_hdr_valid <= 0;
        dbg_led <= 1;
        spi_read_strobe <= 0;
        spi_write_strobe <= 0;
        spi_erase_strobe <= 0;
        m_dhcp_discover_step_request <= 1;
        probeMode <= 0;
        auto_ip_latch <= 0;
        clear_arp_cache <= 0;
        auto_ip_prepare <= 0;
    end else
    begin
/*      if ((mac_matched) || (answerState == init_eeprom_1)) 
      begin*/
        case (answerState)
        init_eeprom_1: begin
             spi_m_tready <= 1;
             spi_start_addr <= DEFAULT_IP_EPROM_ADDR;
             spi_read_strobe <= 1;
             if (dhcp_s_eeprom_process_finished)
             begin
                dhcp_s_eeprom_process_start <= 0;
                answerState <= idle;
             end else
             begin
                dhcp_s_eeprom_process_start <= 1;
             end
        end
        idle: begin
               dhcp_s_eeprom_process_start <= 0;
               dhcp_m_dhcp_discover_start <= 0;
               s_dhcp_offer_axis_tvalid <= 0;
               s_dhcp_offer_start <= 0;
               spi_read_strobe <= 0;
               spi_write_strobe <= 0;
               spi_erase_strobe <= 0;
               spi_m_tready <= 0;
               rx_udp_hdr_ready <= 1;
               ourData_tvalid <= 0;
               ourData_tlast <= 0;
               tx_udp_hdr_valid <= 0;
               rx_udp_payload_axis_tready <= 1;
               probeMode <= 0;
               clear_arp_cache <= 0;
               auto_ip_prepare <= 0;
               auto_ip_latch <= 0;
               // For help to ICMP...
               if (rx_ip_hdr_valid)
               begin
                     // For correct usage of Broadcast/local pipeline!!!
                     tx_udp_ip_dest_ip <= rx_ip_source_ip;  
               end else
               // MDNS request
               if ((rx_udp_hdr_valid)  && (mac_is_mdns))
               begin                         
                  case (rx_udp_dest_port)
                     // Reflect port (just for test purposes)
                     16'd5353: begin
                           // We must flush FIFO. That is why we must check full string
                           // Let's use flag for clear it at first mismatch (but continue checking!!!)
                           string_matched <= 1;

                           spi_start_addr <= 24'h1ff080;
                           spi_read_strobe <= 1;
                           spi_m_tready <= 1;
                           answerState <= mDNS_cmp;
                     end
                 endcase
               end else
               // Regular UDP 
               if ((rx_udp_hdr_valid)  && (mac_matched))
               begin
                  case (rx_udp_dest_port)
                     // Reflect port (just for test purposes)
                     16'd68: begin
//                         tx_udp_ip_source_ip <= local_ip;
//                         tx_udp_ip_dest_ip <= rx_udp_ip_source_ip;  
//                         tx_udp_source_port <= 68; 
//                         tx_udp_dest_port <= 67;   

                         rx_udp_hdr_ready <= 0;			// We are not ready to receive any other UDP packets

                         s_dhcp_offer_start <= 1;		// Start transmitting data from UDP FIFO to slow helepr's FIFO
                         answerState <= dhcp_offer_processing1;
                     end
                     // Reflect port (just for test purposes)
                     16'd1234: begin
                         tx_udp_ip_source_ip <= local_ip;
                         tx_udp_ip_dest_ip <= rx_udp_ip_source_ip;  
                         tx_udp_source_port <= 1234; 
                         tx_udp_dest_port <= rx_udp_source_port;   
                         tx_udp_length <= rx_udp_length;
                         rx_udp_hdr_ready <= 0;
                         answerState <= pre_reflect_1;
                     end
/*                     // TODO: Don't forget remopve this branch!
                     // It is added for debug purposes only
                     1235: begin
                         tx_udp_ip_source_ip <= local_ip;
                         tx_udp_ip_dest_ip <= rx_udp_ip_source_ip;  
                         tx_udp_source_port <= 1235; 
                         tx_udp_dest_port <= rx_udp_source_port;   

                         spi_start_addr <= 24'h1ff040;
                         spi_read_strobe <= 1;
                         spi_m_tready <= 1;

                         tx_udp_length <= 8;

                         answerState <= dbg_string_1;
                     end*/
                     // Read EEPROM Port (0xEEE0)
                     16'heee0: begin
                         rx_udp_hdr_ready <= 0;
                         tx_udp_ip_source_ip <= local_ip;
                         tx_udp_ip_dest_ip <= rx_udp_ip_source_ip;  
                         tx_udp_source_port <= 16'heee0; 
                         tx_udp_dest_port <= 16'heee1;   
                         tx_udp_length <= 128 + 8;   			 // Always sending 128 bytes
                         addr_cnt <= 2;
                         answerState <= rd_eeprom_addr0;
                     end
                     // Write EEPROM
                     16'heee2: begin
                         rx_udp_hdr_ready <= 0;
                         addr_cnt <= 5;
                         answerState <= wr_eeprom_addr0;
                     end
                     // Erase EEPROM
                     16'heeee: begin
                         rx_udp_hdr_ready <= 0;
                         addr_cnt <= 5;
                         answerState <= er_eeprom_addr0;
                     end
                  endcase
               end else if (!rxd)    // Negative logic! DHCP trigger activated
               begin
                     answerState <= dhcp_start;
               end /*else if (!rxd)    // Negative logic! DHCP trigger activated
               begin
                     answerState <= autoIp_start;
               end   */


        end
        // Two states for delay
        // This delay is needed for IP address pipelining
        pre_reflect_1: begin
           ourData_tdata <= rx_udp_payload_axis_tdata;
           ourData_tvalid <= rx_udp_payload_axis_tvalid;
              answerState <= pre_reflect_2;
        end
        pre_reflect_2: begin
           ourData_tdata <= rx_udp_payload_axis_tdata;
           ourData_tvalid <= rx_udp_payload_axis_tvalid;
//              tx_udp_hdr_valid <= 1;
//              if (tx_udp_hdr_ready)
//              begin
//                  answerState <= reflect_2;
//              end else
//              begin
                  answerState <= reflect_1;
//              end
        end
        reflect_1: begin
           ourData_tdata <= rx_udp_payload_axis_tdata;
           ourData_tvalid <= rx_udp_payload_axis_tvalid;
           if (tx_udp_hdr_ready)
              begin
                 tx_udp_hdr_valid <= 1;
                 answerState <= reflect_2;
              end
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
              if ((rx_udp_payload_axis_tlast) || (addr_cnt == 0))
              begin
                  spi_read_strobe <= 1;
                  eeprom_cnt <= 8'd127;	// For read 128 bytes
                  answerState <= rd_eeprom_process;
              end else
              begin
                  addr_cnt <= addr_cnt - 1;
              end
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
/*        rd_eeprom_send1: begin
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
        end*/
        wr_eeprom_addr0: begin
           if (rx_udp_payload_axis_tvalid)
           begin
              eeprom_pwd [23:0] <=  {rx_udp_payload_axis_tdata,eeprom_pwd [23:8]};
              spi_start_addr [23:0] <= {eeprom_pwd [7:0],spi_start_addr [23:8]};
              if ((rx_udp_payload_axis_tlast) || (addr_cnt == 0))
              begin
                 spi_write_strobe <= 1;
                 spi_s_tvalid <= 0;
                 rx_udp_payload_axis_tready <= 0;
                 if (rx_udp_payload_axis_tdata != 8'h57) 
                     answerState <= idle;
                 else
                      answerState <= wr_eeprom_process1;
              end else
              begin
                 case (addr_cnt)
                   02: if (rx_udp_payload_axis_tdata != 8'h45) answerState <= idle;
                   01: if (rx_udp_payload_axis_tdata != 8'h50) answerState <= idle;
                 endcase
                  addr_cnt <= addr_cnt - 1;
              end
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
              eeprom_pwd [23:0] <=  {rx_udp_payload_axis_tdata,eeprom_pwd [23:8]};
              spi_start_addr [23:0] <= {eeprom_pwd [7:0],spi_start_addr [23:8]};
              if ((rx_udp_payload_axis_tlast) || (addr_cnt == 0))
              begin
                  spi_erase_strobe <= 1;
                  spi_s_tvalid <= 0;
                 if (rx_udp_payload_axis_tdata != 8'h43) 
                     answerState <= idle;
                 else
                     answerState <= er_eeprom_process1;
              end else
              begin
                 case (addr_cnt)
                   02: if (rx_udp_payload_axis_tdata != 8'h45) answerState <= idle;
                   01: if (rx_udp_payload_axis_tdata != 8'h50) answerState <= idle;
                 endcase
                  addr_cnt <= addr_cnt - 1;
              end
           end
        end
        er_eeprom_process1: begin
            if (spi_fsm_in_finished)
            begin
                answerState <= idle; 
            end
        end
        dhcp_start: begin
               // negative logic! Wait for release trigger
               if (rxd)
               begin

                  // We are planning to send DHCP_DISCOVERY
                  // This is a first packet in DHCP processing
                  m_dhcp_discover_step_request <= 1;    // This step is discover

                  tx_udp_ip_source_ip <= 32'h00000000;     // Broadcasting...
                  tx_udp_ip_dest_ip <= 32'hffffffff;       // ...
                  tx_udp_source_port <= 16'd68;            // DHCP ports
                  tx_udp_dest_port <= 16'd67;              // ...

                  dhcp_m_dhcp_discover_start <= 1;        // Ask for helper to produce data
                  rx_udp_hdr_ready <= 0;                  // Now we are not ready to receive any data from UDP

                  tx_udp_length <= 8;		// Extra length

                  answerState <= dhcp_fill_0;
               end
        end
        dhcp_fill_0: begin
           dhcp_m_dhcp_discover_tready <= 1;			// We are ready to receive the data from helper
           ourData_tdata <= dhcp_m_dhcp_discover_tdata;         // Receive data from DHCP Helper to FIFO if it is present
           ourData_tvalid <= dhcp_m_dhcp_discover_tvalid;       // ...
           ourData_tlast <= dhcp_m_dhcp_discover_tlast;         // ...

           if (dhcp_m_dhcp_discover_tvalid)			// If really present
           begin 
                tx_udp_length <= tx_udp_length + 1;             // Then increase length
           end
           if (dhcp_m_dhcp_discover_finished)			// If helper has no any more data
           begin
                spi_start_addr <= 24'h1ff040;
                spi_read_strobe <= 1;
                spi_m_tready <= 1;
                answerState <= dbg_string_1;
           end
        end
        dhcp_fill_1: begin
           tx_udp_hdr_valid <= 1;		// Start send to UDP
           ourData_tvalid <= 0;           
           if (tx_udp_hdr_ready)
           begin
                answerState <= idle; 
           end
        end   
        // This state is using for copy incoming FIFO
        // into internal DHCPO Helper's FIFO for slow processing
        // inside that module (using slow clock domain)
        dhcp_offer_processing1: begin
            s_dhcp_offer_axis_tdata <= rx_udp_payload_axis_tdata;
            s_dhcp_offer_axis_tvalid <= rx_udp_payload_axis_tvalid;
            s_dhcp_offer_axis_tlast <= rx_udp_payload_axis_tlast;
            rx_udp_payload_axis_tready <= 1;
            if (rx_udp_payload_axis_tlast)
            begin
                answerState <= dhcp_offer_processing2; 
            end
        end
        dhcp_offer_processing2: begin
            s_dhcp_offer_axis_tvalid <= 0;
            if (s_dhcp_offer_finished)
            begin
                 // Let's stop slow State Machine in DHCP helper
                 s_dhcp_offer_start <= 0;
                 // Are we serving OFFER packet?
                 if (!dhcp_offerIsReceived)  
                 begin     // No! This is answer for DHCPACK. No need senb anything
                      answerState <= idle;
                 end else  // Yes! And we must send DHCPREQUEST
                 begin

                      m_dhcp_discover_step_request <= 0;    

                      tx_udp_ip_source_ip <= 32'h00000000;
                      tx_udp_ip_dest_ip <= 32'hffffffff; 
                      tx_udp_source_port <= 16'd68; 
                      tx_udp_dest_port <= 16'd67;   
                      dhcp_m_dhcp_discover_start <= 1;
     
                      rx_udp_hdr_ready <= 0;
                      tx_udp_length <= 8;		// Extra length

                      answerState <= dhcp_fill_0;
                end
            end
        end
        autoIp_start: begin
               // negative logic! Wait for release trigger
               if (rxd)
               begin
                  probeMode <= 1;

                  // This crazy formula prevents situations of XXX.XXX.255.XXX and XXX.XXX.000.XXX
                  // Why not?
                  tx_udp_ip_dest_ip <= {16'ha9fe,1'b0,auto_ip_online[14:9],1'b1,auto_ip_online[7:0]}; 
                  auto_ip_ip <= {16'ha9fe,1'b0,auto_ip_online[14:9],1'b1,auto_ip_online[7:0]}; 
                  tx_udp_ip_source_ip <= 32'h00000000;

                  clear_arp_cache <= 1;

                  ourData_tdata <= 8'h00;
                  ourData_tlast <= 1;
                  ourData_tvalid <= 1;
                  
                  auto_ip_prepare <= 1;

                  answerState <= autoIp_wait_cache_busy;
               end
        end
        autoIp_wait_cache_busy: begin
              auto_ip_prepare <= 0;
              ourData_tvalid <= 0;
              // Just any. Will not be transmitted!
              tx_udp_source_port <= 16'd68; 
              tx_udp_dest_port <= 16'd67;   
              tx_udp_length <= 1 + 8;		// Extra length

              if (!arp_cache_ready)
              begin
                  clear_arp_cache <= 0;
                  answerState <= autoIp_wait_cache_ready;
              end
        end
        autoIp_wait_cache_ready: begin
            tx_udp_hdr_valid <= 1;
           answerState <= autoIp_wait_fake_packet_send;
        end
        autoIp_wait_fake_packet_send: begin
            tx_udp_hdr_valid <= 0;
            if (udp_tx_busy)
            begin
                answerState <= autoIp_wait_fake_packet_sent; 
            end
        end
        autoIp_wait_fake_packet_sent: begin
           if (!udp_tx_busy)
            begin
                // TODO Add max retry checking
                if ((!probePacketIsDropped)||(auto_ip_matched))
                begin
                    dbg_led <= 1'b1;
                    answerState <= autoIp_start; 
                end else
                begin
//                    dbg_led <= 1'b0;
                    auto_ip_latch <= 1;
                    answerState <= idle; 
                end
            end
        end
        // For Debug Purposes! Remove in future
        // (of course, comment only for use as source 
        // for real production)
        dbg_string_1: begin
           if (spi_m_tvalid)
           begin
               eeprom_cnt <= spi_m_tdata - 1;
               answerState <= dbg_string_2;
           end
        end
        dbg_string_2: begin
           ourData_tdata <= spi_m_tdata;
           ourData_tvalid <= spi_m_tvalid;
           if (spi_m_tvalid)
           begin
               tx_udp_length <= tx_udp_length + 1;
               if (eeprom_cnt == 0)
               begin
                   spi_read_strobe <= 0;
	           spi_m_tready <= 0;

                   answerState <= dhcp_fill_1;
                   ourData_tlast <= 1;
               end else
               begin
                   eeprom_cnt <= eeprom_cnt - 1;
                   ourData_tlast <= 0;
               end
           end
        end
        mDNS_cmp: begin
           rx_udp_payload_axis_tready <= spi_m_tvalid;
             if (spi_m_tvalid)
             begin
                 if (rx_udp_payload_axis_tdata != spi_m_tdata)
                 begin
                     string_matched <= 0;
                 end
             end
             if (rx_udp_payload_axis_tlast & rx_udp_payload_axis_tvalid)
             begin
                 if (string_matched)
                 begin
                       spi_read_strobe <= 0;
                       eeprom_cnt <= 8'h0;
                       tx_udp_length <= 8;
                       tx_udp_ip_source_ip <= local_ip;
                       tx_udp_ip_dest_ip <= rx_udp_ip_source_ip;    // Maybe will be needed change to 224.0.0.251!!!
                       tx_udp_source_port <= 16'd5353; 
                       tx_udp_dest_port <= 16'd5353;   
                       answerState <= mDNS_fill_1;
                end else
                begin
                      answerState <= idle;
                end
             end
        end
         mDNS_fill_1: begin
              ourData_tlast <= 0;
              ourData_tvalid <= 1;
              case (eeprom_cnt[3:0])
                  4'h2 : ourData_tdata <= 8'h84;
                  4'h7 : ourData_tdata <= 8'h01;
                  4'hb : begin
                              spi_start_addr <= 24'h1ff08b;
                              spi_read_strobe <= 1;
                              spi_m_tready <= 1;
                              answerState <= mDNS_fill_2;
                         end
                  default:  ourData_tdata <= 8'h00;
              endcase
              eeprom_cnt <= eeprom_cnt + 8'd1;
              tx_udp_length <= tx_udp_length + 1;
              rx_udp_payload_axis_tready <= 0;
/*              if (string_matched == 1)
                   dbg_led <= 0; */
         end
         mDNS_fill_2: begin
           ourData_tdata <= spi_m_tdata;
           ourData_tvalid <= spi_m_tvalid;
           if (spi_m_tvalid)
           begin
               tx_udp_length <= tx_udp_length + 1;
               if (spi_m_tdata == 8'd0)
               begin
                   spi_read_strobe <= 0;
	           spi_m_tready <= 0;
                   eeprom_cnt <= 8'h0;
                   answerState <= mDNS_fill_3;
               end 
           end
         end
         mDNS_fill_3: begin
//              ourData_tlast <= 0;
//              ourData_tvalid <= 1;
              case (eeprom_cnt [3:0]) 
                  4'h1 : ourData_tdata <= 8'h01;
                  4'h2 : ourData_tdata <= 8'h80;
                  4'h3 : ourData_tdata <= 8'h01;
                  4'h7 : ourData_tdata <= 8'h78;
                  4'h9 : ourData_tdata <= 8'h04;

                  4'ha : ourData_tdata <= local_ip [31:24];
                  4'hb : ourData_tdata <= local_ip [23:16];
                  4'hc : ourData_tdata <= local_ip [15:8];
                  4'hd : begin
                              ourData_tdata <= local_ip [7:0];
                              ourData_tlast <= 1;
                              // Same functionality as we need...
                              answerState <= dhcp_fill_1;
                         end
                  default:  ourData_tdata <= 8'h00;
              endcase
              eeprom_cnt <= eeprom_cnt + 8'd1;
              tx_udp_length <= tx_udp_length + 1;
              rx_udp_payload_axis_tready <= 0;
/*              if (string_matched == 1)
                   dbg_led <= 0; */
         end
        endcase
//     end // mac_matched
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

assign dbg_out [6:0] = spi_m_tdata [6:0];
assign dbg_out [7] = spi_m_tvalid;
assign dbg_out [13:8] = rx_udp_payload_axis_tdata [5:0];
assign dbg_out [14] = dbg_led;

/*assign dbg_out [7:0] = ourData_tdata;
assign dbg_out [8] = ourData_tvalid;
assign dbg_out [9] = ourData_tready;
assign dbg_out [10] = ourData_tlast;*/


endmodule
