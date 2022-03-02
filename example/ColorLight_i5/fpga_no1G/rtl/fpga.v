module fpga #(
    parameter TARGET = "LATTICE"
)
(
    input              clk_i,
    output reg         led_o,

//    output             spi_flash_sck,
    output             spi_flash_mosi,
    input              spi_flash_miso,    
    output             spi_flash_cs,

    output wire        eth_clocks_tx,
    input  wire        eth_clocks_rx,
    output wire        eth_rst_n,
    input  wire        eth_rx_ctl,
    input  wire [3:0]  eth_rx_data,
    output wire        eth_tx_ctl,
    output wire [3:0]  eth_tx_data,
    output             eth_mdc,
    inout              eth_mdio,

//    input              rxd,                   // It is uses as "Start DHCP" trigger
    output [15:0]      dbg_out

);

USRMCLK USRMCLK(
	.USRMCLKI(spi_flash_sck),
	.USRMCLKTS(1'd0)
);


localparam MAX = 12_500_000;
localparam WIDTH = $clog2(MAX);

wire clk125;
wire clk50;
wire clk_system;


wire rst;
// Reset Generator
rst_gen rst_inst (.clk_i(clk_system), .rst_i(1'b0), .rst_o(rst));


reg  [WIDTH-1:0] cpt_s;
wire [WIDTH-1:0] cpt_next_s = cpt_s + 1'b1;

// Blink Functionality
wire end_s = cpt_s == MAX-1;

always @(posedge clk_i) begin
    cpt_s <= (rst || end_s) ? {WIDTH{1'b0}} : cpt_next_s;
    if (rst) begin
        led_o <= 1'b0;
    end else if (end_s) begin
        led_o <= ~led_o;
    end
end

assign eth_rst_n = 1;

(* FREQUENCY_PIN_CLKI="25" *)
(* FREQUENCY_PIN_CLKOP="125" *)
(* FREQUENCY_PIN_CLKOS="104.167" *)
(* FREQUENCY_PIN_CLKOS2="52.0833" *)
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
        .CLKOS_DIV(6),
        .CLKOS_CPHASE(2),
        .CLKOS_FPHASE(0),
        .CLKOS2_ENABLE("ENABLED"),
        .CLKOS2_DIV(12),
        .CLKOS2_CPHASE(2),
        .CLKOS2_FPHASE(0),
        .FEEDBK_PATH("CLKOP"),
        .CLKFB_DIV(5)
    ) pll_i (
        .RST(1'b0),
        .STDBY(1'b0),
        .CLKI(clk_i),
        .CLKOP(clk125),
        .CLKOS(clk_system),
        .CLKOS2(clk50),
        .CLKFB(clk125),
        .CLKINTFB(),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b1),
        .PHASESTEP(1'b1),
        .PHASELOADREG(1'b1),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
        .LOCK()
	);


// MDIO logic needs for disable 1G capability

reg [19:0] delay_reg = 20'hfffff;

reg [4:0] mdio_cmd_phy_addr = 5'h00;
reg [4:0] mdio_cmd_reg_addr = 5'h00;
reg [15:0] mdio_cmd_data = 16'd0;
reg [1:0] mdio_cmd_opcode = 2'b01;
reg mdio_cmd_valid = 1'b0;
wire mdio_cmd_ready;

reg [3:0] mdio_state;

always @(posedge clk125) begin
    if (rst) begin
        mdio_state <= 0;
        delay_reg <= 20'hfffff;
        mdio_cmd_reg_addr <= 5'h00;
        mdio_cmd_data <= 16'd0;
        mdio_cmd_valid <= 1'b0;
        mdio_cmd_opcode = 2'b01;
    end else begin
        mdio_cmd_valid <= mdio_cmd_valid & !mdio_cmd_ready;
        if (delay_reg != 0) begin
            delay_reg <= delay_reg - 1;
        end else if (!mdio_cmd_ready) begin
            // wait for ready
            mdio_state <= mdio_state;
        end else begin
            mdio_cmd_valid <= 1'b0;
            case (mdio_state)
                4'd0: begin
                    // Disable 1000M Capability
                    mdio_cmd_reg_addr <= 5'h09;
                    mdio_cmd_data <= 16'h0000;
                    mdio_cmd_valid <= 1'b1;
                    mdio_state <= 4'd1;
                end
                4'd1: begin
                    // Re Negotiate
                    mdio_cmd_reg_addr <= 5'h00;
                    mdio_cmd_data <= 16'h1340;
                    mdio_cmd_valid <= 1'b1;
                    mdio_state <= 4'd12;
                end
                // ...
                // Values from 1 to 11 are reserved
                // ...
                4'd12: begin
                    // done
                    mdio_state <= 4'd12;
                end
            endcase
        end
    end
end

wire mdc;
wire mdio_i;
wire mdio_o;
wire mdio_t;

mdio_master
mdio_master_inst (
    .clk(clk125),
    .rst(rst),

    .cmd_phy_addr(mdio_cmd_phy_addr),
    .cmd_reg_addr(mdio_cmd_reg_addr),
    .cmd_data(mdio_cmd_data),
    .cmd_opcode(mdio_cmd_opcode),
    .cmd_valid(mdio_cmd_valid),
    .cmd_ready(mdio_cmd_ready),

    .data_out(),
    .data_out_valid(),
    .data_out_ready(1'b1),

    .mdc_o(mdc),
    .mdio_i(mdio_i),
    .mdio_o(mdio_o),
    .mdio_t(mdio_t),

    .busy(),

    .prescale(8'd3)
);

assign eth_mdc = mdc;
assign mdio_i = eth_mdio;
assign eth_mdio = mdio_t ? 1'bz : mdio_o;

assign dbg_out [0] = mdc;
assign dbg_out [1] = mdio_i;
assign dbg_out [2] = mdio_o;
assign dbg_out [3] = mdio_t;
assign dbg_out [4] = mdio_cmd_valid;
assign dbg_out [5] = mdio_cmd_ready;
assign dbg_out [6] = mdio_cmd_valid;



fpga_core #(
    .TARGET(TARGET),
    .USE_CLK90("FALSE")
) ethCore0
(
    .rst(rst),
    .clk125(clk125),
    .clk_system(clk_system),
    .clk25(clk50),
    .clk90(clk125),	

    .spi_flash_sck(spi_flash_sck),
    .spi_flash_mosi(spi_flash_mosi),
    .spi_flash_miso(spi_flash_miso),
    .spi_flash_cs(spi_flash_cs), 

    .rxd (1'b1/*rxd*/),			// It is uses as "Start DHCP" trigger

//    .dbg_led (led_o),
//    .dbg_out (dbg_out),

    .phy0_tx_clk(eth_clocks_tx),
    .phy0_rx_clk(eth_clocks_rx),
    .phy0_rx_ctl(eth_rx_ctl),
    .phy0_rxd(eth_rx_data),
    .phy0_tx_ctl(eth_tx_ctl),
    .phy0_txd(eth_tx_data),
//    .phy0_mdc(eth_mdc),
//    .phy0_mdio(eth_mdio)
);

endmodule
