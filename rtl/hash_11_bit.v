module hash_11_bit
(
   input [31:0] in_data,
   output [10:0] out_data
);

wire [7:0] ip_1;
wire [7:0] ip_2;
wire [7:0] ip_3;
wire [7:0] ip_4;

assign ip_1 = in_data [31:24];
assign ip_2 = in_data [23:16];
assign ip_3 = in_data [15:8];
assign ip_4 = in_data [7:0];

assign out_data [0] =             ip_3 [0];
assign out_data [1] =             ip_3 [1]            ^ ip_1 [0];
assign out_data [2] =             ip_3 [2]            ^ ip_1 [7];
assign out_data [3] =  ip_4 [7] ^ ip_3 [3] ^ ip_2 [0] ^ ip_1 [1];
assign out_data [4] =  ip_4 [6] ^ ip_3 [4] ^ ip_2 [4] ^ ip_1 [6];
assign out_data [5] =  ip_4 [5] ^ ip_3 [5] ^ ip_2 [1] ^ ip_1 [2];
assign out_data [6] =  ip_4 [4] ^ ip_3 [6] ^ ip_2 [5] ^ ip_1 [5];
assign out_data [7] =  ip_4 [3] ^ ip_3 [7] ^ ip_2 [2] ^ ip_1 [3];
assign out_data [8] =  ip_4 [2]            ^ ip_2 [6] ^ ip_1 [4];
assign out_data [9] =  ip_4 [1]            ^ ip_2 [3];
assign out_data [10] = ip_4 [0]            ^ ip_2 [7];
endmodule
