module broadcast_checker(
    input  wire        clk,
    input  wire        rst,

    input [31:0]       dest_ip,

    // Pipelined outputs
    output reg         m_ip_addr_is_broadcast,
    output reg         m_ip_addr_is_subnet_broadcast,
    output reg         m_ip_request_is_local,

    /*
     * Configuration
     */
    input  wire [31:0]            gateway_ip,
    input  wire [31:0]            subnet_mask

);

// Pipeline Registers
//reg [3:0] pipeline_stage;
/*reg [3:0] ip_addr_is_broadcast;
reg [3:0] request_is_local;
reg [3:0] ip_addr_is_subnet_broadcast;*/
reg [31:0] ip_with_subnet;

reg [31:0] ip_with_gateway;
reg [31:0] ip_with_gateway_and_submask;


// Pipeline DataPath
always @(posedge clk)
begin
/*       ip_addr_is_broadcast [3] <= (dest_ip[31:24] == 8'hff); 
       ip_addr_is_broadcast [2] <= (dest_ip[23:16] == 8'hff); 
       ip_addr_is_broadcast [1] <= (dest_ip[15:8] == 8'hff); 
       ip_addr_is_broadcast [0] <= (dest_ip[7:0] == 8'hff); 

       m_ip_addr_is_broadcast <= ip_addr_is_broadcast [3] & ip_addr_is_broadcast [2]
                               & ip_addr_is_broadcast [1] & ip_addr_is_broadcast [0];*/

       m_ip_addr_is_broadcast <= dest_ip[31] & dest_ip [30]
                               & dest_ip[29] & dest_ip [28]
                               & dest_ip[27] & dest_ip [26]
                               & dest_ip[25] & dest_ip [24]
                               & dest_ip[23] & dest_ip [22]
                               & dest_ip[21] & dest_ip [20]
                               & dest_ip[19] & dest_ip [18]
                               & dest_ip[17] & dest_ip [16]
                               & dest_ip[15] & dest_ip [14]
                               & dest_ip[13] & dest_ip [12]
                               & dest_ip[11] & dest_ip [10]
                               & dest_ip[9]  & dest_ip [8] 
                               & dest_ip[7]  & dest_ip [6] 
                               & dest_ip[5]  & dest_ip [4] 
                               & dest_ip[3]  & dest_ip [2] 
                               & dest_ip[1]  & dest_ip [0] ;

       ip_with_subnet <= dest_ip | subnet_mask;

/*       ip_addr_is_subnet_broadcast [3] <= (ip_with_subnet[31:24] == 8'hff); 
       ip_addr_is_subnet_broadcast [2] <= (ip_with_subnet[23:16] == 8'hff); 
       ip_addr_is_subnet_broadcast [1] <= (ip_with_subnet[15:8] == 8'hff); 
       ip_addr_is_subnet_broadcast [0] <= (ip_with_subnet[7:0] == 8'hff); 

       m_ip_addr_is_subnet_broadcast <= ip_addr_is_subnet_broadcast [3] 
                                      & ip_addr_is_subnet_broadcast [2]
                                      & ip_addr_is_subnet_broadcast [1] 
                                      & ip_addr_is_subnet_broadcast [0];*/

      m_ip_addr_is_subnet_broadcast <= ip_with_subnet[31] & ip_with_subnet[30]  
                                     & ip_with_subnet[29] & ip_with_subnet[28]
                                     & ip_with_subnet[27] & ip_with_subnet[26]
                                     & ip_with_subnet[25] & ip_with_subnet[24]
                                     & ip_with_subnet[23] & ip_with_subnet[22]
                                     & ip_with_subnet[21] & ip_with_subnet[20]
                                     & ip_with_subnet[19] & ip_with_subnet[18]
                                     & ip_with_subnet[17] & ip_with_subnet[16]
                                     & ip_with_subnet[15] & ip_with_subnet[14]
                                     & ip_with_subnet[13] & ip_with_subnet[12]
                                     & ip_with_subnet[11] & ip_with_subnet[10]
                                     & ip_with_subnet[9]  & ip_with_subnet[8] 
                                     & ip_with_subnet[7]  & ip_with_subnet[6] 
                                     & ip_with_subnet[5]  & ip_with_subnet[4] 
                                     & ip_with_subnet[3]  & ip_with_subnet[2] 
                                     & ip_with_subnet[1]  & ip_with_subnet[0];

      ip_with_gateway <= dest_ip ^ gateway_ip;
      ip_with_gateway_and_submask <= ip_with_gateway & subnet_mask;


/*      request_is_local [3] <= (ip_with_gateway_and_submask[31:24] == 8'h00);
      request_is_local [2] <= (ip_with_gateway_and_submask[23:16] == 8'h00);
      request_is_local [1] <= (ip_with_gateway_and_submask[15:8] == 8'h00);
      request_is_local [0] <= (ip_with_gateway_and_submask[7:0] == 8'h00);

      m_ip_request_is_local <= request_is_local [3] & request_is_local [2]
                          & request_is_local [1] & request_is_local [0];*/

     m_ip_request_is_local <= !(ip_with_gateway_and_submask[31] | ip_with_gateway_and_submask[30]
                              | ip_with_gateway_and_submask[29] | ip_with_gateway_and_submask[28]
                              | ip_with_gateway_and_submask[27] | ip_with_gateway_and_submask[26]
                              | ip_with_gateway_and_submask[25] | ip_with_gateway_and_submask[24]
                              | ip_with_gateway_and_submask[23] | ip_with_gateway_and_submask[22]
                              | ip_with_gateway_and_submask[21] | ip_with_gateway_and_submask[20]
                              | ip_with_gateway_and_submask[19] | ip_with_gateway_and_submask[18]
                              | ip_with_gateway_and_submask[17] | ip_with_gateway_and_submask[16]
                              | ip_with_gateway_and_submask[15] | ip_with_gateway_and_submask[14]
                              | ip_with_gateway_and_submask[13] | ip_with_gateway_and_submask[12]
                              | ip_with_gateway_and_submask[11] | ip_with_gateway_and_submask[10]
                              | ip_with_gateway_and_submask[9]  | ip_with_gateway_and_submask[8]
                              | ip_with_gateway_and_submask[7]  | ip_with_gateway_and_submask[6]
                              | ip_with_gateway_and_submask[5]  | ip_with_gateway_and_submask[4]
                              | ip_with_gateway_and_submask[3]  | ip_with_gateway_and_submask[2]
                              | ip_with_gateway_and_submask[1]  | ip_with_gateway_and_submask[0] );

end



endmodule
