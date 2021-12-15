module fpga #(
    parameter TARGET = "LATTICE"
)
(
    input              clk48,
    output             rgb_led0_r,
    output reg         rgb_led0_g,
    output             rgb_led0_b,

    input  wire        rmii_clk,
    input  wire [1:0]  rmii_rxd,
    input  wire        rmii_rx_crs_dv,
    output wire [1:0]  rmii_txd,
    output wire        rmii_tx_en,

    output             rmii_mdc,
    inout              rmii_mdio
);

wire sys_clk;

//assign test = sys_clk;

/*ODDRX1F ODDRX1F(
	.D0(1'd1),
	.D1(1'd0),
	.SCLK(clk48),
	.Q(test)
);

*/
localparam MAX = 45_000_000;
localparam WIDTH = $clog2(MAX);

wire rst;

// Reset Generator
rst_gen rst_inst (.clk_i(clk48), .rst_i(1'b0), .rst_o(rst));

reg  [WIDTH-1:0] cpt_s;
wire [WIDTH-1:0] cpt_next_s = cpt_s + 1'b1;

// Blink Functionality
wire end_s = cpt_s == MAX-1;

always @(posedge sys_clk) begin
    cpt_s <= (rst || end_s) ? {WIDTH{1'b0}} : cpt_next_s;
    if (rst) begin
        rgb_led0_g <= 1'b0;
    end else if (end_s) begin
        rgb_led0_g <= ~rgb_led0_g;
    end
end

wire clkfb;
(* FREQUENCY_PIN_CLKI="48" *)
(* FREQUENCY_PIN_CLKOP="90" *)
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
        .CLKI_DIV(8),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(7),
        .CLKOP_CPHASE(3),
        .CLKOP_FPHASE(0),
        .FEEDBK_PATH("INT_OP"),
        .CLKFB_DIV(15)
    ) pll_i (
        .RST(1'b0),
        .STDBY(1'b0),
        .CLKI(clk48),
        .CLKOP(sys_clk),
        .CLKFB(clkfb),
        .CLKINTFB(clkfb),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b1),
        .PHASESTEP(1'b1),
        .PHASELOADREG(1'b1),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
        .LOCK()
	);

fpga_core #(
    .TARGET(TARGET),
) ethCore0
(
    .rst(rst),
    .sys_clk(sys_clk),

    .rmii_clk(rmii_clk),
    .rmii_rxd(rmii_rxd),
    .rmii_rx_crs_dv(rmii_rx_crs_dv),
    .rmii_txd(rmii_txd),
    .rmii_tx_en(rmii_tx_en),    

    .rgb_led0_r (rgb_led0_r),
    .rgb_led0_b (rgb_led0_b),

    .rmii_mdc(rmii_mdc),
    .rmii_mdio(rmii_mdio)
);
endmodule
