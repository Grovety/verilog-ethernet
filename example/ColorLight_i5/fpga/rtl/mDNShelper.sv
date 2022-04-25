module mDNShelper
(
    input             clk,
    input             rst,
    input [47:0]      mac,
    output reg        mac_is_mdns
);

reg mac_is_mdns_1 [3:0];


always @ (posedge clk)
begin
     
     // Compare with constanst is too expensive function in Yosys. 
     // That is why let's we use binary function. Stupid? Yes, it is!
     // But FMax is better for curreent Yosys version

     // 01 00 5E 00 00 FB
     // 010... means 0000 0001 0000
     mac_is_mdns_1 [3] <=    (~mac [47]) & (~mac [46]) & (~mac [45]) & (~mac [44]) & 
                             (~mac [43]) & (~mac [42]) & (~mac [41]) & mac [40] & 
                             (~mac [39]) & (~mac [38]) & (~mac [37]) & (~mac [36]);
     /// ...05E... means 0000 0101 1110
     mac_is_mdns_1 [2] <=    (~mac [35]) & (~mac [34]) & (~mac [33]) & (~mac [32]) & 
                             (~mac [31]) &  mac [30] & (~mac [29]) &  mac [28] & 
                              mac [27] &  mac [26] &  mac [25] & (~mac [24]);
     // ...000... means 0000 0000 0000
     mac_is_mdns_1 [1] <=    (~mac [23]) & (~mac [22]) & (~mac [21]) & (~mac [20]) & 
                             (~mac [19]) & (~mac [18]) & (~mac [17]) & (~mac [16]) & 
                             (~mac [15]) & (~mac [14]) & (~mac [13]) & (~mac [12]);
     // ...0FB means 0000 1111 1011
     mac_is_mdns_1 [0] <=   (~mac [11]) & (~mac [10]) & (~mac [9]) & (~mac [8]) & 
                             mac [7]  &  mac [6] &   mac [5] &  mac [4] & 
                             mac [3]  & (~mac [2]) &   mac [1] &  mac [0];
     mac_is_mdns <= mac_is_mdns_1 [0] & mac_is_mdns_1 [1] & mac_is_mdns_1 [2] & mac_is_mdns_1 [3];
end

endmodule

