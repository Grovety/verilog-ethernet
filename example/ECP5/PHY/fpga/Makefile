TARGET=blink
TOP=blink

# local files for target project
OBJS+=../rtl/blink.v 
OBJS+=../rtl/rst_gen.v
OBJS+=../rtl/mdio_master.v
OBJS+=../rtl/mdio_control.v
#global files from library
OBJS+=../../../../rtl/iddr.v
OBJS+=../../../../rtl/oddr.v

TRELLIS=/usr/local/share/trellis

all: ${TARGET}.bit

$(TARGET).json: $(OBJS)
	yosys -p "synth_ecp5 -json $@" $(OBJS)

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
