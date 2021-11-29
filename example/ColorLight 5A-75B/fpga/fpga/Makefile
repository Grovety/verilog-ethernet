# FPGA settings
FPGA_TOP=fpga
FPGA_FAMILY = ECP5
FPGA_DEVICE = LFE5U-25F-6BG256C

# Files for synthesis
SYN_FILES = ../rtl/fpga.v 
SYN_FILES += ../rtl/fpga_core.v 
SYN_FILES += ../rtl/rst_gen.v
SYN_FILES += ../rtl/lfsr_yosys.v
SYN_FILES += ../../../../rtl/iddr.v
SYN_FILES += ../../../../rtl/oddr.v
SYN_FILES += ../../../../rtl/ssio_ddr_in.v
SYN_FILES += ../../../../rtl/ssio_ddr_out.v
SYN_FILES += ../../../../rtl/rgmii_phy_if.v
SYN_FILES += ../../../../lib/axis/rtl/axis_async_fifo.v
SYN_FILES += ../../../../lib/axis/rtl/axis_async_fifo_adapter.v
SYN_FILES += ../../../../rtl/axis_gmii_tx.v
SYN_FILES += ../../../../rtl/axis_gmii_rx.v
SYN_FILES += ../../../../rtl/eth_mac_1g.v
SYN_FILES += ../../../../rtl/eth_mac_1g_rgmii.v
SYN_FILES += ../../../../rtl/eth_mac_1g_rgmii_fifo.v
SYN_FILES += ../../../../rtl/eth_axis_rx.v
SYN_FILES += ../../../../rtl/eth_axis_tx.v      
SYN_FILES += ../../../../rtl/udp_complete.v      
SYN_FILES += ../../../../rtl/udp_checksum_gen.v     
SYN_FILES += ../../../../rtl/udp.v        
SYN_FILES += ../../../../rtl/udp_ip_rx.v       
SYN_FILES += ../../../../rtl/udp_ip_tx.v       
SYN_FILES += ../../../../rtl/ip_complete.v      
SYN_FILES += ../../../../rtl/ip.v        
SYN_FILES += ../../../../rtl/ip_eth_rx.v       
SYN_FILES += ../../../../rtl/ip_eth_tx.v       
SYN_FILES += ../../../../rtl/ip_arb_mux.v      
SYN_FILES += ../../../../rtl/ip_mux.v       
SYN_FILES += ../../../../rtl/arp.v        
SYN_FILES += ../../../../rtl/arp_cache.v       
SYN_FILES += ../../../../rtl/arp_eth_rx.v      
SYN_FILES += ../../../../rtl/arp_eth_tx.v      
SYN_FILES += ../../../../rtl/eth_arb_mux.v      
SYN_FILES += ../../../../rtl/eth_mux.v       
SYN_FILES += ../../../../rtl/hash_11_bit.v
SYN_FILES += ../../../../lib/axis/rtl/arbiter.v     
SYN_FILES += ../../../../lib/axis/rtl/priority_encoder.v   
SYN_FILES += ../../../../lib/axis/rtl/axis_fifo.v    
SYN_FILES += ../../../../lib/axis/rtl/sync_reset.v  

# TRELLIS files
TRELLIS = /usr/local/share/trellis

include ../common/lattice.mk

program: ${FPGA_TOP}.svf
	openocd -f ../config.cfg
