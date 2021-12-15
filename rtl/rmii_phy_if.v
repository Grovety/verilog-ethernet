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
 * RMII PHY interface
 */
module rmii_phy_if #
(
    // target ("SIM", "GENERIC", "XILINX", "ALTERA")
    parameter TARGET = "GENERIC",
    // Clock input style ("BUFG", "BUFR", "BUFIO", "BUFIO2")
    // Use BUFR for Virtex-5, Virtex-6, 7-series
    // Use BUFG for Ultrascale
    // Use BUFIO2 for Spartan-6
    parameter CLOCK_INPUT_STYLE = "BUFIO2"
)
(
    input  wire        rst,

    /*
     * RMII interface to MAC
     */
    output wire        mac_rmii_clk,
    output wire        mac_rmii_rx_rst,
    output wire [1:0]  mac_rmii_rxd,
    output wire        mac_rmii_rx_crs_dv,
    output wire        mac_rmii_tx_rst,
    input  wire [1:0]  mac_rmii_txd,
    input  wire        mac_rmii_tx_en,

    /*
     * RMII interface to PHY
     */
    input  wire        phy_rmii_clk,
    input  wire [1:0]  phy_rmii_rxd,
    input  wire        phy_rmii_rx_crs_dv,
    output wire [1:0]  phy_rmii_txd,
    output wire        phy_rmii_tx_en
);

ssio_sdr_in #
(
    .TARGET(TARGET),
    .CLOCK_INPUT_STYLE(CLOCK_INPUT_STYLE),
    .WIDTH(5)
)
rx_ssio_sdr_inst (
    .input_clk(phy_rmii_clk),
    .input_d({phy_rmii_rxd, phy_rmii_rx_crs_dv}),
    .output_clk(mac_rmii_clk),
    .output_q({mac_rmii_rxd, mac_rmii_rx_crs_dv})
);

(* IOB = "TRUE" *)
reg [3:0] phy_rmii_txd_reg = 4'd0;
(* IOB = "TRUE" *)
reg phy_rmii_tx_en_reg = 1'b0;

assign phy_rmii_txd = phy_rmii_txd_reg;
assign phy_rmii_tx_en = phy_rmii_tx_en_reg;

always @(posedge mac_rmii_clk) begin
    phy_rmii_txd_reg <= mac_rmii_txd;
    phy_rmii_tx_en_reg <= mac_rmii_tx_en;
end

generate

if (TARGET == "XILINX") begin
    BUFG
    mii_bufg_inst (
        .I(phy_rmii_clk),
        .O(mac_rmii_clk)
    );
end else begin
    assign mac_rmii_clk = phy_rmii_clk;
end

endgenerate

// reset sync
reg [3:0] tx_rst_reg = 4'hf;
assign mac_rmii_tx_rst = tx_rst_reg[0];

always @(posedge mac_rmii_clk or posedge rst) begin
    if (rst) begin
        tx_rst_reg <= 4'hf;
    end else begin
        tx_rst_reg <= {1'b0, tx_rst_reg[3:1]};
    end
end

reg [3:0] rx_rst_reg = 4'hf;
assign mac_rmii_rx_rst = rx_rst_reg[0];

always @(posedge mac_rmii_clk or posedge rst) begin
    if (rst) begin
        rx_rst_reg <= 4'hf;
    end else begin
        rx_rst_reg <= {1'b0, rx_rst_reg[3:1]};
    end
end

endmodule
