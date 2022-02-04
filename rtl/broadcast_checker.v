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
reg [3:0] ip_addr_is_broadcast;
reg [3:0] ip_addr_is_subnet_broadcast;
reg [31:0] ip_with_subnet;

reg [31:0] ip_with_gateway;
reg [31:0] ip_with_gateway_and_submask;

reg [3:0] request_is_local;

// Pipeline DataPath
always @(posedge clk)
begin
       ip_addr_is_broadcast [3] <= (dest_ip[31:24] == 8'hff); 
       ip_addr_is_broadcast [2] <= (dest_ip[23:16] == 8'hff); 
       ip_addr_is_broadcast [1] <= (dest_ip[15:8] == 8'hff); 
       ip_addr_is_broadcast [0] <= (dest_ip[7:0] == 8'hff); 

       m_ip_addr_is_broadcast <= ip_addr_is_broadcast [3] & ip_addr_is_broadcast [2]
                               & ip_addr_is_broadcast [1] & ip_addr_is_broadcast [0];

       ip_with_subnet <= dest_ip | subnet_mask;

       ip_addr_is_subnet_broadcast [3] <= (ip_with_subnet[31:24] == 8'hff); 
       ip_addr_is_subnet_broadcast [2] <= (ip_with_subnet[23:16] == 8'hff); 
       ip_addr_is_subnet_broadcast [1] <= (ip_with_subnet[15:8] == 8'hff); 
       ip_addr_is_subnet_broadcast [0] <= (ip_with_subnet[7:0] == 8'hff); 

       m_ip_addr_is_subnet_broadcast <= ip_addr_is_subnet_broadcast [3] 
                                      & ip_addr_is_subnet_broadcast [2]
                                      & ip_addr_is_subnet_broadcast [1] 
                                      & ip_addr_is_subnet_broadcast [0];

      ip_with_gateway <= dest_ip ^ gateway_ip;
      ip_with_gateway_and_submask <= ip_with_gateway & subnet_mask;

      request_is_local [3] <= (ip_with_gateway_and_submask[31:24] == 8'h00);
      request_is_local [2] <= (ip_with_gateway_and_submask[23:16] == 8'h00);
      request_is_local [1] <= (ip_with_gateway_and_submask[15:8] == 8'h00);
      request_is_local [0] <= (ip_with_gateway_and_submask[7:0] == 8'h00);

      m_ip_request_is_local <= request_is_local [3] & request_is_local [2]
                          & request_is_local [1] & request_is_local [0];
end



endmodule
