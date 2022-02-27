module fpga_core #(
    parameter TARGET = "GENERIC",		// For correct simulation! Override by "LATTICE" from parent module!!!
    parameter USE_CLK90 = "TRUE"                // For correct simulation! Override by "FALSE" from parent module!!!
)
(
    input              clk125,
    input              clk_system,
    input              clk25,
    input              rst,
    input              clk90,
    output wire        phy0_tx_clk,
    input  wire        phy0_rx_clk,
    input  wire        phy0_rx_ctl,
    input  wire [3:0]  phy0_rxd,
    output wire        phy0_tx_ctl,
    output wire [3:0]  phy0_txd,
    output             phy0_mdc,
    inout              phy0_mdio,
    output wire        phy0_reset_n,
    input  wire        phy0_int_n,

    output             dbg_led,

    output             spi_flash_sck,
    output             spi_flash_mosi,
    input              spi_flash_miso,    
    output             spi_flash_cs,

// Just for successfull TestBench
    input  wire       phy1_rx_clk,
    input  wire [3:0] phy1_rxd,
    input  wire       phy1_rx_ctl,
    output wire       phy1_tx_clk,
    output wire [3:0] phy1_txd,
    output wire       phy1_tx_ctl,
    output wire       phy1_reset_n,
    input  wire       phy1_int_n,

    output [15:0]            dbg_out
);

assign phy0_reset_n = ~rst;
assign phy1_reset_n = ~rst;


// AXI between MAC and Ethernet modules
wire [7:0] rx_axis_tdata;
wire rx_axis_tvalid;
wire rx_axis_tready;
wire rx_axis_tlast;
wire rx_axis_tuser;
wire [1:0]rx_axis_tkeed;

wire [7:0] tx_axis_tdata;
wire tx_axis_tvalid;
wire tx_axis_tready;
wire tx_axis_tlast;
wire tx_axis_tuser;
wire [1:0]tx_axis_tkeed;

eth_mac_1g_rgmii_fifo #(
    .TARGET(TARGET),
    .USE_CLK90(USE_CLK90),
    .ENABLE_PADDING(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_DEPTH(4096),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(4096),
    .RX_FRAME_FIFO(1)
)
eth_mac_inst (
    .gtx_clk(clk125),
    .gtx_clk90(clk90),
    .gtx_rst(rst),
    .logic_clk(clk_system),
    .logic_rst(rst),
    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(tx_axis_tuser),
    .rx_axis_tdata(rx_axis_tdata),
    .rx_axis_tvalid(rx_axis_tvalid),
    .rx_axis_tready(rx_axis_tready),
    .rx_axis_tlast(rx_axis_tlast),
    .rx_axis_tuser(rx_axis_tuser),
    .rgmii_rx_clk(phy0_rx_clk),
    .rgmii_rxd(phy0_rxd),
    .rgmii_rx_ctl(phy0_rx_ctl),
    .rgmii_tx_clk(phy0_tx_clk),
    .rgmii_txd(phy0_txd),
    .rgmii_tx_ctl(phy0_tx_ctl),    
    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(),
    .speed(),
    .ifg_delay(12)
);

fpga_logic #(
    .TARGET(TARGET),
    .USE_CLK90(USE_CLK90),
)
ourLogic (
    .clk(clk_system),
    .rst(rst),
    .clk25(clk25),
    .clk90(clk90),

    .dbg_led(dbg_led),
    .dbg_out(dbg_out),

    .spi_flash_sck(spi_flash_sck),
    .spi_flash_mosi(spi_flash_mosi),
    .spi_flash_miso(spi_flash_miso),   
    .spi_flash_cs(spi_flash_cs),

    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tkeep(tx_axis_tkeep),
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(tx_axis_tuser),

    .rx_axis_tdata (rx_axis_tdata),
    .rx_axis_tkeep (rx_axis_tkeep),
    .rx_axis_tvalid(rx_axis_tvalid),
    .rx_axis_tready(rx_axis_tready),
    .rx_axis_tlast (rx_axis_tlast),
    .rx_axis_tuser (rx_axis_tuser)
);
  
endmodule
