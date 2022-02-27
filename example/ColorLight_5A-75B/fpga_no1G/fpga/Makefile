# FPGA settings
FPGA_TOP=fpga
FPGA_FAMILY = ECP5
FPGA_DEVICE = LFE5U-25F-6BG256C

# Files for synthesis
SYN_FILES = rtl/fpga.v 
SYN_FILES += rtl/fpga_core.sv 
SYN_FILES += rtl/rst_gen.v
SYN_FILES += rtl/lfsr_yosys.v
SYN_FILES += rtl/SpiFlashReader.sv
SYN_FILES += rtl/fpga_logic.sv
SYN_FILES += rtl/icmp.sv
SYN_FILES += rtl/DHCPhelper.sv
SYN_FILES += rtl/prng.sv
SYN_FILES += lib/eth/rtl/iddr.v
SYN_FILES += lib/eth/rtl/oddr.v
SYN_FILES += lib/eth/rtl/ssio_ddr_in.v
SYN_FILES += lib/eth/rtl/ssio_ddr_out.v
SYN_FILES += lib/eth/rtl/rgmii_phy_if.v
SYN_FILES += lib/eth/lib/axis/rtl/axis_async_fifo.v
SYN_FILES += lib/eth/lib/axis/rtl/axis_async_fifo_adapter.v
SYN_FILES += lib/eth/rtl/axis_gmii_tx.v
SYN_FILES += lib/eth/rtl/axis_gmii_rx.v
SYN_FILES += lib/eth/rtl/eth_mac_1g.v
SYN_FILES += lib/eth/rtl/eth_mac_1g_rgmii.v
SYN_FILES += lib/eth/rtl/eth_mac_1g_rgmii_fifo.v
SYN_FILES += lib/eth/rtl/eth_axis_rx.v
SYN_FILES += lib/eth/rtl/eth_axis_tx.v      
SYN_FILES += lib/eth/rtl/udp_complete.v      
SYN_FILES += lib/eth/rtl/udp_checksum_gen.v     
SYN_FILES += lib/eth/rtl/udp.v        
SYN_FILES += lib/eth/rtl/udp_ip_rx.v       
SYN_FILES += lib/eth/rtl/udp_ip_tx.v       
SYN_FILES += lib/eth/rtl/ip_complete.v      
SYN_FILES += lib/eth/rtl/ip.v        
SYN_FILES += lib/eth/rtl/broadcast_checker.v
SYN_FILES += lib/eth/rtl/ip_eth_rx.v       
SYN_FILES += lib/eth/rtl/ip_eth_tx.v       
SYN_FILES += lib/eth/rtl/ip_arb_mux.v      
SYN_FILES += lib/eth/rtl/ip_mux.v       
SYN_FILES += lib/eth/rtl/arp.v        
SYN_FILES += lib/eth/rtl/arp_cache.v       
SYN_FILES += lib/eth/rtl/arp_eth_rx.v      
SYN_FILES += lib/eth/rtl/arp_eth_tx.v      
SYN_FILES += lib/eth/rtl/eth_arb_mux.v      
SYN_FILES += lib/eth/rtl/eth_mux.v       
SYN_FILES += lib/eth/rtl/hash_11_bit.v
SYN_FILES += lib/eth/lib/axis/rtl/arbiter.v     
SYN_FILES += lib/eth/lib/axis/rtl/priority_encoder.v   
SYN_FILES += lib/eth/lib/axis/rtl/axis_fifo.v    
SYN_FILES += lib/eth/lib/axis/rtl/sync_reset.v  

#Nextpnr parameters
NEXTPNR_PARAMS := --25k
NEXTPNR_PARAMS += --package CABGA256
NEXTPNR_PARAMS += --speed 6
NEXTPNR_PARAMS += --json $(FPGA_TOP).json
NEXTPNR_PARAMS += --textcfg $(FPGA_TOP)_out.config
NEXTPNR_PARAMS += --lpf ../pinout_v7.lpf
NEXTPNR_PARAMS += --freq 166
NEXTPNR_PARAMS += --quiet
NEXTPNR_PARAMS += --force
NEXTPNR_PARAMS += --log PlaceAndRoute.log

#IP address properties
#IP_ADDRESS := 192.168.2.128
#SUBNET_MASK := 255.255.255.0
#GATEWAY := 192.168.2.1

# TRELLIS files
TRELLIS = /usr/local/share/trellis

include ../common/lattice.mk

program: ${FPGA_TOP}.svf
	openocd -f ../config.cfg
