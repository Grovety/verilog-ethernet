# Verilog Ethernet ECP5-25 Example Design

## Introduction

This example design targets the Colorlight 5A-75B board with Lattice ECP5-25 FPGA.

The design by default listens to UDP port 1234 at IP address 192.168.1.128 and
will echo back any packets received.  The design will also respond correctly
to ARP requests.  

*  FPGA: LFE5U-25F-6BG256C
*  PHY: 2x Broadcom B50612D (board version 7)
*  PHY: 2x Realtek RTL8211FD (board version 8)

## How to build

Run make to build.  Ensure that the Yosys toolchain components are
in PATH.  

## How to test

Run make program to program the board with the OpenOCD software.  Then run

    netcat -u 192.168.1.128 1234

to open a UDP connection to port 1234.  Any text entered into netcat will be
echoed back after pressing enter.

It is also possible to use hping to test the design by running

    hping 192.168.1.128 -2 -p 1234 -d 1024
