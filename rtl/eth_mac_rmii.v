/*

Copyright (c) 2019 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * 10M/100M Ethernet MAC with MII interface
 */
module eth_mac_rmii #(
    // target ("SIM", "GENERIC", "XILINX", "ALTERA")
    parameter TARGET = "GENERIC",
    // Clock input style ("BUFG", "BUFR", "BUFIO", "BUFIO2")
    // Use BUFR for Virtex-5, Virtex-6, 7-series
    // Use BUFG for Ultrascale
    // Use BUFIO2 for Spartan-6
    parameter CLOCK_INPUT_STYLE = "BUFIO2",
    parameter ENABLE_PADDING = 1,
    parameter MIN_FRAME_LENGTH = 64
)
(
    input  wire        rst,
    output wire        rx_clk,
    output wire        rx_rst,
    output wire        tx_clk,
    output wire        tx_rst,
    /*
     * AXI input
     */
    input  wire [7:0]  tx_axis_tdata,
    input  wire        tx_axis_tvalid,
    output wire        tx_axis_tready,
    input  wire        tx_axis_tlast,
    input  wire        tx_axis_tuser,
    /*
     * AXI output
     */
    output wire [7:0]  rx_axis_tdata,
    output wire        rx_axis_tvalid,
    output wire        rx_axis_tlast,
    output wire        rx_axis_tuser,
    /*
     * RMII interface
     */
    input  wire        rmii_clk,
    input  wire [1:0]  rmii_rxd,
    input  wire        rmii_rx_crs_dv,
    output wire [1:0]  rmii_txd,
    output wire        rmii_tx_en,
    /*
     * Status
     */
    output wire        tx_start_packet,
    output wire        tx_error_underflow,
    output wire        rx_start_packet,
    output wire        rx_error_bad_frame,
    output wire        rx_error_bad_fcs,
    /*
     * Configuration
     */
    input  wire [7:0]  ifg_delay
);

reg  [3:0]  mac_mii_rxd;
reg         mac_mii_rx_dv;
wire        mac_mii_rx_er = 0;
wire [3:0]  mac_mii_txd;
wire        mac_mii_tx_en;
wire        mac_mii_tx_er;

wire [1:0]  mac_rmii_rxd;
wire        mac_rmii_rx_crs_dv;
reg  [1:0]  mac_rmii_txd;
reg         mac_rmii_tx_en;

reg         rx_clk_enable;
reg         tx_clk_enable;


rmii_phy_if #(
    .TARGET(TARGET),
    .CLOCK_INPUT_STYLE(CLOCK_INPUT_STYLE)
)
rmii_phy_if_inst (
    .rst(rst),

    .mac_rmii_clk(rx_clk),
    .mac_rmii_rx_rst(rx_rst),
    .mac_rmii_rxd(mac_rmii_rxd),
    .mac_rmii_rx_crs_dv(mac_rmii_rx_crs_dv),
    .mac_rmii_tx_rst(tx_rst),
    .mac_rmii_txd(mac_rmii_txd),
    .mac_rmii_tx_en(mac_rmii_tx_en),

    .phy_rmii_clk(rmii_clk),
    .phy_rmii_rxd(rmii_rxd),
    .phy_rmii_rx_crs_dv(rmii_rx_crs_dv),
    .phy_rmii_txd(rmii_txd),
    .phy_rmii_tx_en(rmii_tx_en)
);

assign tx_clk = rx_clk;

eth_mac_1g #(
    .ENABLE_PADDING(ENABLE_PADDING),
    .MIN_FRAME_LENGTH(MIN_FRAME_LENGTH)
)
eth_mac_1g_inst (
    .tx_clk(tx_clk),
    .tx_rst(tx_rst),
    .rx_clk(rx_clk),
    .rx_rst(rx_rst),
    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(tx_axis_tuser),
    .rx_axis_tdata(rx_axis_tdata),
    .rx_axis_tvalid(rx_axis_tvalid),
    .rx_axis_tlast(rx_axis_tlast),
    .rx_axis_tuser(rx_axis_tuser),
    .gmii_rxd(mac_mii_rxd),
    .gmii_rx_dv(mac_mii_rx_dv),
    .gmii_rx_er(mac_mii_rx_er),
    .gmii_txd(mac_mii_txd),
    .gmii_tx_en(mac_mii_tx_en),
    .gmii_tx_er(mac_mii_tx_er),
    .rx_clk_enable(rx_clk_enable),
    .tx_clk_enable(tx_clk_enable),
    .rx_mii_select(1'b1),
    .tx_mii_select(1'b1),
    .tx_start_packet(tx_start_packet),
    .tx_error_underflow(tx_error_underflow),
    .rx_start_packet(rx_start_packet),
    .rx_error_bad_frame(rx_error_bad_frame),
    .rx_error_bad_fcs(rx_error_bad_fcs),
    .ifg_delay(ifg_delay)
);


// RX State Machine
localparam STATE_IDLE               = 0;
localparam STATE_CRS                = 1;
localparam STATE_SFD                = 2;
localparam STATE_NIBBLE0            = 3;
localparam STATE_NIBBLE1            = 4;

reg [2:0] state;

always @ (posedge rx_clk) begin
    if (rx_rst) begin
        state <= STATE_IDLE;
        mac_mii_rxd <= 0;
        mac_mii_rx_dv <= 0;
        rx_clk_enable <= 0;
    end else begin
        case (state)
            STATE_IDLE: begin
                mac_mii_rx_dv <= 0;
                mac_mii_rxd <= 4'b0000;
                rx_clk_enable <= ~rx_clk_enable;
                if (mac_rmii_rx_crs_dv) begin
                    state <= STATE_CRS;
                end
            end
            STATE_CRS: begin
                mac_mii_rx_dv <= 1;
                rx_clk_enable <= ~rx_clk_enable;
                if (mac_rmii_rxd == 2'b0) begin
                    mac_mii_rxd <= 4'b0000;
                    state <= STATE_CRS;
                end else if (mac_rmii_rxd == 2'b01) begin
                    mac_mii_rxd <= 4'b0101;
                    state <= STATE_SFD;
                end else begin
                    mac_mii_rxd <= 4'b0000;
                    state <= STATE_IDLE;
                end
            end
            STATE_SFD: begin
                if (mac_rmii_rxd == 2'b11) begin
                    rx_clk_enable <= 1;
                    mac_mii_rxd <= 4'b01101;
                    state <= STATE_NIBBLE0;
                end else if (mac_rmii_rxd == 2'b01) begin
                    rx_clk_enable <= ~rx_clk_enable;
                    mac_mii_rxd <= 4'b0101;
                    state <= STATE_SFD;
                end else begin
                    rx_clk_enable <= ~rx_clk_enable;
                    mac_mii_rxd <= 4'b0000;
                    state <= STATE_IDLE;
                end
            end
            STATE_NIBBLE0: begin
                rx_clk_enable <= 0;
                mac_mii_rxd [1:0] <= mac_rmii_rxd;
                state <= STATE_NIBBLE1;
            end
            STATE_NIBBLE1: begin
                rx_clk_enable <= 1;
                mac_mii_rxd [3:2] <= mac_rmii_rxd;
                if (mac_rmii_rx_crs_dv) begin
                    state <= STATE_NIBBLE0;
                end else begin
                    mac_mii_rx_dv <= 0;
                    state <= STATE_IDLE;
                end
            end
            default: begin
                state <= STATE_IDLE;
                mac_mii_rxd <= 0;
                mac_mii_rx_dv <= 0;
                rx_clk_enable <= 0;
            end
        endcase
    end
     
end

// TX Functionality 
reg [1:0] txd_latch;
reg       tx_en_latch;
always @(posedge tx_clk)
begin
    if (tx_rst)
    begin
         tx_clk_enable <= 0;
    end else
    begin
         tx_clk_enable <= !tx_clk_enable;
         if (tx_clk_enable)
         begin
              mac_rmii_txd <= mac_mii_txd [1:0];
              txd_latch <= mac_mii_txd [3:2];
              mac_rmii_tx_en <= mac_mii_tx_en;
              tx_en_latch <= mac_mii_tx_en;
         end else
         begin
              mac_rmii_txd <= txd_latch;
              mac_rmii_tx_en <= tx_en_latch;
         end
    end
end

endmodule
