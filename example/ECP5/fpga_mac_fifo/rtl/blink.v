module blink (
    input      clk_i,
    output reg led_o,

    output wire eth_clocks_tx,
    input wire eth_clocks_rx,
    output wire eth_rst_n,
//    input wire eth_mdio,
//    output wire eth_mdc,
    input wire eth_rx_ctl,
    input wire [3:0] eth_rx_data,
    output wire eth_tx_ctl,
    output wire [3:0] eth_tx_data,

    output [6:0] test,

    input rxd,
    output txd,

    output eth_mdc,
    inout  eth_mdio

);
localparam MAX = 12_500_000;
localparam WIDTH = $clog2(MAX);

(* keep = "true" *) wire eth_rx_clk;
wire eth_rx_rst;
(* keep = "true" *) wire eth_tx_clk;
assign eth_rx_clk = eth_clocks_rx;
assign eth_tx_clk = eth_rx_clk;
wire ethphy_eth_tx_clk_o;

wire clk;
wire clk90;

wire rst_s;
wire clk_s;

assign clk_s = clk_i;
rst_gen rst_inst (.clk_i(clk_s), .rst_i(1'b0), .rst_o(rst_s));

reg  [WIDTH-1:0] cpt_s;
wire [WIDTH-1:0] cpt_next_s = cpt_s + 1'b1;

wire             end_s = cpt_s == MAX-1;

always @(posedge clk_s) begin
    cpt_s <= (rst_s || end_s) ? {WIDTH{1'b0}} : cpt_next_s;

    if (rst_s)
        led_o <= 1'b0;
    else if (end_s)
        led_o <= ~led_o;
end

/*oddr #(
    .TARGET("LATTICE"),
    .WIDTH(2)
)
data_oddr_inst (
    .clk(clk_s),
    .d1({test_cnt[2], test_cnt[0]}),
    .d2({test_cnt[3], test_cnt[1]}),
    .q(test[1:0])
);*/
assign eth_rst_n = 1;
wire clkfb;
(* FREQUENCY_PIN_CLKI="25" *)
(* FREQUENCY_PIN_CLKOP="125" *)
(* FREQUENCY_PIN_CLKOS="125" *)
(* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)
EHXPLLL #(
        .PLLRST_ENA("DISABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENABLE("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .OUTDIVIDER_MUXA("DIVA"),
        .OUTDIVIDER_MUXB("DIVB"),
        .OUTDIVIDER_MUXC("DIVC"),
        .OUTDIVIDER_MUXD("DIVD"),
        .CLKI_DIV(1),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(5),
        .CLKOP_CPHASE(2),
        .CLKOP_FPHASE(0),
        .CLKOS_ENABLE("ENABLED"),
        .CLKOS_DIV(5),
        .CLKOS_CPHASE(3),
        .CLKOS_FPHASE(2),
        .FEEDBK_PATH("INT_OP"),
        .CLKFB_DIV(5)
    ) pll_i (
        .RST(1'b0),
        .STDBY(1'b0),
        .CLKI(clk_i),
        .CLKOP(clk),
        .CLKOS(clk90),
        .CLKFB(clkfb),
        .CLKINTFB(clkfb),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b1),
        .PHASESTEP(1'b1),
        .PHASELOADREG(1'b1),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
        .LOCK(locked)
	);

wire mdio_to_us;
wire mdio_from_us;
wire mdio_t;

TRELLIS_IO #(
	.DIR("BIDIR")
) TRELLIS_IO (
	.B(eth_mdio),
	.I(mdio_from_us),
	.T(mdio_t),
	.O(mdio_to_us)
);

mdio_control mdio(
    .clk125 (clk),
    .reset (rst_s),
    .rxd (rxd),
    .txd (txd),
    
    .control (),

    .mdc_o(eth_mdc),
    .mdio_i(mdio_to_us),
    .mdio_o(mdio_from_us),
    .mdio_t(mdio_t)


);
wire [1:0] speed;
wire debug;
assign test [1:0] = {speed[1],debug};
assign test [2] = clk_s;
assign test [3] = eth_clocks_rx;
assign test [6:4] = 0;

eth_mac_1g_rgmii_fifo #(
    .TARGET("LATTICE"),
    .USE_CLK90("TRUE"),
    .ENABLE_PADDING(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_DEPTH(4096),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(4096),
    .RX_FRAME_FIFO(1)

) eth_mac_inst
(
    .gtx_clk(clk),
    .gtx_clk90(clk90),
    .gtx_rst(rst_s),
    .logic_clk(clk),
    .logic_rst(rst_s),

    .tx_axis_tdata(/*tx_axis_tdata*/),
    .tx_axis_tvalid(/*tx_axis_tvalid*/),
    .tx_axis_tready(/*tx_axis_tready*/),
    .tx_axis_tlast(/*tx_axis_tlast*/),
    .tx_axis_tuser(/*tx_axis_tuser*/),

    .rx_axis_tdata(/*rx_axis_tdata*/),
    .rx_axis_tvalid(),
    .rx_axis_tready(1'b1/*rx_axis_tready*/),
    .rx_axis_tlast(/*rx_axis_tlast*/),
    .rx_axis_tuser(/*rx_axis_tuser*/),

    .rgmii_rx_clk(eth_clocks_rx),
    .rgmii_rxd(eth_rx_data),
    .rgmii_rx_ctl(eth_rx_ctl),
    .rgmii_tx_clk(eth_clocks_tx),
    .rgmii_txd(eth_tx_data),
    .rgmii_tx_ctl(eth_tx_ctl),
    // Empty in original design
    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(debug),
    .speed(speed),

    .ifg_delay(12)

);

endmodule
