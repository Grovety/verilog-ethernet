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
)
pll_i (
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
) 
ethCore0 (
    .rst(rst),
    .sys_clk(sys_clk),

    .rmii_clk(rmii_clk),
    .rmii_rxd(rmii_rxd),
    .rmii_rx_crs_dv(rmii_rx_crs_dv),
    .rmii_txd(rmii_txd),
    .rmii_tx_en(rmii_tx_en),    

    .rgb_led0_r (rgb_led0_r),
    .rgb_led0_b (rgb_led0_b)
);

// MDIO logic needs for increase Elastic Buffer Size

reg [15:0] delay_reg = 16'hffff;

reg [4:0] mdio_cmd_phy_addr = 5'h00;
reg [4:0] mdio_cmd_reg_addr = 5'h00;
reg [15:0] mdio_cmd_data = 16'd0;
reg [1:0] mdio_cmd_opcode = 2'b01;
reg mdio_cmd_valid = 1'b0;
wire mdio_cmd_ready;

reg [3:0] mdio_state;

always @(posedge clk48) begin
    if (rst) begin
        mdio_state <= 0;
        delay_reg <= 16'hffff;
        mdio_cmd_reg_addr <= 5'h00;
        mdio_cmd_data <= 16'd0;
        mdio_cmd_valid <= 1'b0;
        mdio_cmd_opcode = 2'b01;
    end else begin
        mdio_cmd_valid <= mdio_cmd_valid & !mdio_cmd_ready;
        if (delay_reg > 0) begin
            delay_reg <= delay_reg - 1;
        end else if (!mdio_cmd_ready) begin
            // wait for ready
            mdio_state <= mdio_state;
        end else begin
            mdio_cmd_valid <= 1'b0;
            case (mdio_state)
                4'd0: begin
                    mdio_cmd_reg_addr <= 5'h17;
                    mdio_cmd_data <= 16'h0022;
                    mdio_cmd_valid <= 1'b1;
                    mdio_state <= 4'd12;
                end
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
    .clk(clk48),
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

assign rmii_mdc = mdc;
assign mdio_i = rmii_mdio;
assign rmii_mdio = mdio_t ? 1'bz : mdio_o;

endmodule
