/*

Copyright (c) 2014-2018 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * ARP cache
 */
module arp_cache #(
    parameter CACHE_ADDR_WIDTH = 11
)
(
    input  wire        clk,
    input  wire        rst,

    /*
     * Cache query
     */
    input  wire        query_request_valid,
    output wire        query_request_ready,
    input  wire [31:0] query_request_ip,

    output wire        query_response_valid,
    input  wire        query_response_ready,
    output reg         query_response_error,
    output reg  [47:0] query_response_mac,

    /*
     * Cache write
     */
    input  wire        write_request_valid,
    output reg         write_request_ready,
    input  wire [31:0] write_request_ip,
    input  wire [47:0] write_request_mac,

    /*
     * Configuration
     */
    input  wire        clear_cache
);

assign query_request_ready = 1;

wire [11:0] hash_wr;
hash_11_bit hash_w (
     .in_data (write_request_ip),
     .out_data (hash_wr)
);

// Memory
reg [80:0] ram [(2**CACHE_ADDR_WIDTH)-1:0];
reg ram_we;
reg [CACHE_ADDR_WIDTH-1:0] ram_addr_w;
reg [80:0] ram_data_w;

reg [CACHE_ADDR_WIDTH-1:0] ram_addr_r;
reg [80:0] ram_last_data_r;
reg [80:0] ram_last_data_r2;

// RAM definition
always @(posedge clk)
begin
      if (ram_we)
      begin
          ram [ram_addr_w] <= ram_data_w;
      end
      ram_last_data_r <= ram [ram_addr_r];
      ram_last_data_r2 <= ram_last_data_r;
end

// Read Datapath
reg [31:0] ip_latch;
// Why mismatch? Better to compare with 0!
reg [7:0] ip_mismatch_1;

wire [11:0] hash_rd;
hash_11_bit hash_r (
     .in_data (query_request_ip),
     .out_data (hash_rd)
);

reg [3:0] data_valid;
reg ip_valid;

always @(posedge clk)
begin
     if (rst)
     begin
         data_valid <= 0;
     end else
     begin
        // Pipeline Stage 1
        ip_latch <= query_request_ip;
        ram_addr_r <= hash_rd;
        
        // Pipeline Stage 2
        ip_mismatch_1 [7] <= !(ram_last_data_r2[79:76] == ip_latch [31:28]);
        ip_mismatch_1 [6] <= !(ram_last_data_r2[75:72] == ip_latch [27:24]);
        ip_mismatch_1 [5] <= !(ram_last_data_r2[71:68] == ip_latch [23:20]);
        ip_mismatch_1 [4] <= !(ram_last_data_r2[67:64] == ip_latch [19:16]);
        ip_mismatch_1 [3] <= !(ram_last_data_r2[63:60] == ip_latch [15:12]);
        ip_mismatch_1 [2] <= !(ram_last_data_r2[59:56] == ip_latch [11:8]);
        ip_mismatch_1 [1] <= !(ram_last_data_r2[55:52] == ip_latch [7:4]);
        ip_mismatch_1 [0] <= !(ram_last_data_r2[51:48] == ip_latch [3:0]);
        ip_valid <= ram_last_data_r2 [80];
        
        // Pipeline Stage 3
        if  ((ip_mismatch_1 [7:0] == 8'b00000000) && ip_valid)
        begin
             query_response_mac <= ram_last_data_r2[47:0];
             query_response_error <= 0;
        end else
        begin
             query_response_error <= 1;
        end
        
        if (query_request_valid==0)
        begin
           data_valid <= 0;
        end else
        begin
           data_valid <= {1'b1,data_valid [3:1]};
        end
        
     end
end

assign query_response_valid = data_valid [0];

// Write FSM
localparam WR_STATE_IDLE               = 0;
localparam WR_STATE_CLEAR_CACHE        = 1;
reg [1:0] wr_state;
reg [CACHE_ADDR_WIDTH-1:0] addr_reg;

always @(posedge clk)
begin
   if (rst == 1)
   begin
       write_request_ready <= 0;
       wr_state <= WR_STATE_CLEAR_CACHE;
       addr_reg <= {CACHE_ADDR_WIDTH{1'b1}};
       ram_we <= 0;
   end else
   begin
      case (wr_state)
         WR_STATE_IDLE: begin
             if (clear_cache == 1)
             begin
                 write_request_ready <= 0;
                 wr_state <= WR_STATE_CLEAR_CACHE;
                 addr_reg <= {CACHE_ADDR_WIDTH{1'b1}};
                 ram_we <= 0;
             end else 
             begin
                  write_request_ready <= 1;
                  ram_addr_w <= hash_wr;
                  ram_data_w <= {1'b1,write_request_ip,write_request_mac};
                  ram_we <= write_request_valid;
             end
         end
         WR_STATE_CLEAR_CACHE: begin
             ram_addr_w <= addr_reg;
             ram_data_w <= 0;
             ram_we <= 1;
             
             addr_reg <= addr_reg - 1;
             if (addr_reg == 0)
                wr_state <= WR_STATE_IDLE;
         end
         default: begin
             write_request_ready <= 0;
             wr_state <= WR_STATE_CLEAR_CACHE;
             addr_reg <= {CACHE_ADDR_WIDTH{1'b1}};
         end
       endcase
   end
end

endmodule
