###################################################################
# 
# Parameters:
# FPGA_TOP - Top module name
# SYN_FILES - space-separated list of source files
# BOARD - Version of the Colorlight board, possible values 
# ecp5_v7(by default), ecp5_v8 
# 
# Example:
# 
# FPGA_TOP = blink
# SYN_FILES = rtl/fpga.v rtl/clocks.v
# BOARD=ecp5_v7
# 
###################################################################

# phony targets
.PHONY: prog clean

TARGET=blink
FPGA_TOP=blink
BOARD=ecp5_v7

# local files for target project
SYN_FILES+=../rtl/blink.v 
SYN_FILES+=../rtl/rst_gen.v
SYN_FILES+=../rtl/mdio_master.v
SYN_FILES+=../rtl/mdio_control.v
SYN_FILES+=../rtl/lfsr_yosys.v
SYN_FILES+=../rtl/axistouart.v
#global files from library
SYN_FILES+=../../../../rtl/iddr.v
SYN_FILES+=../../../../rtl/oddr.v
SYN_FILES+=../../../../rtl/ssio_ddr_in.v
SYN_FILES+=../../../../rtl/ssio_ddr_out.v
SYN_FILES+=../../../../rtl/rgmii_phy_if.v
SYN_FILES+=../../../../lib/axis/rtl/axis_async_fifo.v
SYN_FILES+=../../../../lib/axis/rtl/axis_async_fifo_adapter.v
SYN_FILES+=../../../../rtl/axis_gmii_tx.v
SYN_FILES+=../../../../rtl/axis_gmii_rx.v
SYN_FILES+=../../../../rtl/eth_mac_1g.v
SYN_FILES+=../../../../rtl/eth_mac_1g_rgmii.v
SYN_FILES+=../../../../rtl/eth_mac_1g_rgmii_fifo.v
SYN_FILES+=../../../../rtl/eth_axis_rx.v
SYN_FILES+=../../../../rtl/eth_axis_tx.v      
SYN_FILES+=../../../../rtl/udp_complete.v      
SYN_FILES+=../../../../rtl/udp_checksum_gen.v     
SYN_FILES+=../../../../rtl/udp.v        
SYN_FILES+=../../../../rtl/udp_ip_rx.v       
SYN_FILES+=../../../../rtl/udp_ip_tx.v       
SYN_FILES+=../../../../rtl/ip_complete.v      
SYN_FILES+=../../../../rtl/ip.v        
SYN_FILES+=../../../../rtl/ip_eth_rx.v       
SYN_FILES+=../../../../rtl/ip_eth_tx.v       
SYN_FILES+=../../../../rtl/ip_arb_mux.v      
SYN_FILES+=../../../../rtl/ip_mux.v       
SYN_FILES+=../../../../rtl/arp.v        
SYN_FILES+=../../../../rtl/arp_cache.v       
SYN_FILES+=../../../../rtl/arp_eth_rx.v      
SYN_FILES+=../../../../rtl/arp_eth_tx.v      
SYN_FILES+=../../../../rtl/eth_arb_mux.v      
SYN_FILES+=../../../../rtl/eth_mux.v       
SYN_FILES+=../../../../rtl/hash_11_bit.v
SYN_FILES+=../../../../lib/axis/rtl/arbiter.v     
SYN_FILES+=../../../../lib/axis/rtl/priority_encoder.v   
SYN_FILES+=../../../../lib/axis/rtl/axis_fifo.v    
SYN_FILES+=../../../../lib/axis/rtl/sync_reset.v              
TRELLIS=/usr/local/share/trellis

###################################################################
# Main Targets
#
# all: build everything
# clean: remove output files and database
# program: download firmware
###################################################################

all: ${TARGET}.bit

clean:
	rm -f *.svf *.bit *.config *.ys

program: ${TARGET}.svf
	openocd -f ../myConfig.cfg
#	openFPGALoader -c digilent_hs2 $(TARGET).bit

###################################################################
# Target implementations
###################################################################

$(TARGET).json: $(SYN_FILES)
	yosys -p "synth_ecp5 -top $(FPGA_TOP) -json $@" $(SYN_FILES)

$(TARGET)_out.config: $(TARGET).json
	nextpnr-ecp5 --25k --package CABGA256 --speed 6 --json $< --textcfg $@ --lpf ../$(BOARD).lpf --freq 166

$(TARGET).bit: $(TARGET)_out.config
	ecppack --svf ${TARGET}.svf $< $@

${TARGET}.svf : ${TARGET}.bit