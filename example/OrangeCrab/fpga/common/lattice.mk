###################################################################
# 
# Lattice Yosys FPGA Makefile
# 
###################################################################
# 
# Parameters:
# FPGA_TOP - Top module name
# FPGA_FAMILY - FPGA family (e.g. VirtexUltrascale)
# FPGA_DEVICE - FPGA device (e.g. xcvu095-ffva2104-2-e)
# BOARD - Version of the Colorlight board, possible values
# ecp5_v7(by default), ecp5_v8
# SYN_FILES - space-separated list of source files
# 
# Example:
# 
# FPGA_TOP = fpga
# FPGA_FAMILY = ECP5
# FPGA_DEVICE = LFE5U-25F-6BG256C
# SYN_FILES = rtl/fpga.v
# TRELLIS = /usr/local/share/trellis
# include ../common/lattice.mk
# 
###################################################################

# phony targets
.PHONY: clean fpga

BOARD:=orangecrab_r0.2

SYN_FILES_REL = $(patsubst %, ../%, $(SYN_FILES))

###################################################################
# Main Targets
#
# all: build everything
# clean: remove output files
###################################################################

all: fpga

fpga: $(FPGA_TOP).bit

clean:
	rm -f *.svf *.bit *.config *.ys *.json

###################################################################
# Target implementations
###################################################################

$(FPGA_TOP).json: $(SYN_FILES_REL)
	yosys -q -l "Synth.log" -p "synth_ecp5 -top $(FPGA_TOP) -json $@ -abc2" $(SYN_FILES_REL)

$(FPGA_TOP)_out.config: $(FPGA_TOP).json
	nextpnr-ecp5 --25k --package CSFBGA285 --speed 6 --json $< --textcfg $@ --lpf ../common/$(BOARD).pcf --freq 166 --log PlaceAndRoute.log

$(FPGA_TOP).bit: $(FPGA_TOP)_out.config
	ecppack --compress --svf ${FPGA_TOP}.svf $< $@

${FPGA_TOP}.svf : ${FPGA_TOP}.bit
