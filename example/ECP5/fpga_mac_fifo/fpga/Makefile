TARGET=blink
TOP=blink

# local files for target project
OBJS+=../rtl/blink.v 
OBJS+=../rtl/rst_gen.v
OBJS+=../rtl/mdio_master.v
OBJS+=../rtl/mdio_control.v
OBJS+=../rtl/lfsr_yosys.v
#global files from library
OBJS+=../../../../rtl/iddr.v
OBJS+=../../../../rtl/oddr.v
OBJS+=../../../../rtl/ssio_ddr_in.v
OBJS+=../../../../rtl/ssio_ddr_out.v
OBJS+=../../../../rtl/rgmii_phy_if.v
OBJS+=../../../../lib/axis/rtl/axis_async_fifo.v
OBJS+=../../../../lib/axis/rtl/axis_async_fifo_adapter.v
OBJS+=../../../../rtl/axis_gmii_tx.v
OBJS+=../../../../rtl/axis_gmii_rx.v
#OBJS+=../../../../rtl/lfsr.v
OBJS+=../../../../rtl/eth_mac_1g.v
OBJS+=../../../../rtl/eth_mac_1g_rgmii.v
OBJS+=../../../../rtl/eth_mac_1g_rgmii_fifo.v
TRELLIS=/usr/local/share/trellis

all: ${TARGET}.bit

$(TARGET).json: $(OBJS)
	yosys -p "synth_ecp5 -top $(TOP) -json $@" $(OBJS)

$(TARGET)_out.config: $(TARGET).json
	nextpnr-ecp5 --25k --package CABGA256 --speed 6 --json $< --textcfg $@ --lpf ../$(TARGET).lpf --freq 65

$(TARGET).bit: $(TARGET)_out.config
	ecppack --svf ${TARGET}.svf $< $@

${TARGET}.svf : ${TARGET}.bit

prog: ${TARGET}.svf
	openocd -f ../myConfig.cfg
#	openFPGALoader -c digilent_hs2 $(TARGET).bit

clean:
	rm -f *.svf *.bit *.config *.ys

.PHONY: prog clean
