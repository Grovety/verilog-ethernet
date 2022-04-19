module icmp
(
    input clk,
	 input rst,
	 
    /*
     * IP traffic from us to host
     */
    output reg         m_ip_hdr_valid,
    input  wire        m_ip_hdr_ready,
    output wire [5:0]  m_ip_dscp,
    output wire [1:0]  m_ip_ecn,
    output reg  [15:0] m_ip_length,
    output reg  [7:0]  m_ip_ttl,
    output wire [7:0]  m_ip_protocol,
    output reg  [31:0] m_ip_source_ip,
    output reg  [31:0] m_ip_dest_ip,
    output reg  [7:0]  m_ip_payload_axis_tdata,
    output reg         m_ip_payload_axis_tvalid,
    input  wire        m_ip_payload_axis_tready,
    output reg         m_ip_payload_axis_tlast,
    output wire        m_ip_payload_axis_tuser,
    
    /*
     * IP traffic from host to us
     */
    input  wire        s_ip_hdr_valid,
    output wire        s_ip_hdr_ready,
//    input  wire [47:0] s_ip_eth_dest_mac,
//    input  wire [47:0] s_ip_eth_src_mac,
    input  wire [15:0] s_ip_eth_type,
    input  wire [3:0]  s_ip_version,
    input  wire [3:0]  s_ip_ihl,
    input  wire [5:0]  s_ip_dscp,
    input  wire [1:0]  s_ip_ecn,
    input  wire [15:0] s_ip_length,
//    input  wire [15:0] s_ip_identification,
//    input  wire [2:0]  s_ip_flags,
//    input  wire [12:0] s_ip_fragment_offset,
    input  wire [7:0]  s_ip_ttl,
    input  wire [7:0]  s_ip_protocol,
//    input  wire [15:0] s_ip_header_checksum,
    input  wire [31:0] s_ip_source_ip,
    input  wire [31:0] s_ip_dest_ip,
    input  wire [7:0]  s_ip_payload_axis_tdata,
    input  wire        s_ip_payload_axis_tvalid,
    output reg         s_ip_payload_axis_tready,
    input  wire        s_ip_payload_axis_tlast,
    input  wire        s_ip_payload_axis_tuser,
	 
    input  wire [31:0] local_ip
	 

);



assign s_ip_hdr_ready = 1;
// I still cannot understand why tuser is needed
assign m_ip_payload_axis_tuser = 0;
assign m_ip_dscp = 0;
assign m_ip_ecn = 0;
assign m_ip_protocol = 8'd01; // ICMP


// We need have local storage for keep Ping Data
// Why cannot send directly? Maybe ARP request will be needed
// before transacxtion. That is why main FIFOs will be used for it
// As a result - local storage is mandatory
reg [7:0] local_storage [2047:0];
reg ram_we;
reg [10:0] ram_addr_w;
reg [7:0] ram_data_w;
// For pipelining!!!
reg [10:0] ram_addr_r;
reg [7:0] ram_last_data_r;

reg [10:0] local_storage_ptr;

always @(posedge clk)
begin
      if (ram_we)
      begin
          local_storage [ram_addr_w] <= ram_data_w;
      end
      ram_last_data_r <= local_storage [ram_addr_r];
end

reg [19:0] checksum;
// This is not strange constructuion!
// This is pipeline!
reg [15:0] csStorage;
reg       csCalcCsNow;
reg       csCalcCsPrev;
reg       resetCs;

// Pileplied checksum caclulator
always @ (posedge clk)
begin
    csCalcCsPrev <= csCalcCsNow;
    if (resetCs)
	       checksum <= 16'h0000;
	  else begin
	       if ((csCalcCsPrev == 0) && (csCalcCsNow == 1))
			 begin
			    checksum <=  checksum + csStorage; 
			 end
	  end
end


typedef enum /*logic [3:0]*/ {
                 idle, checkRequestType,checkRequestCode,
					  delay1,delay2,
					  fillLocalStorage,
					  startTransmit,startTransmit2,
					  sendFirstOctet00,sendSecondOctet00,
					  sendFirstOctetCS,sendSecondOctetCS,
					  sendDataOctet,
					  qqq
             } state_t;
				 
state_t state;
reg [15:0] csForSend;

always @(posedge clk)
begin
     if (rst)
	  begin
	     state <= idle;
		  s_ip_payload_axis_tready <= 1;
		  m_ip_payload_axis_tvalid <= 0;
		  m_ip_payload_axis_tlast <= 0;
		  m_ip_hdr_valid <= 0;
		  ram_we <= 0;
		  csCalcCsNow <= 0;
	  end else
	  begin
	     case (state)
			  idle: begin
			      m_ip_payload_axis_tlast <= 0;
			      m_ip_payload_axis_tvalid <= 0;
					resetCs <= 1;
			      // We received ICMP request
					if ((s_ip_hdr_valid) && (s_ip_protocol == 8'd01))
					begin
						 
//						 s_ip_payload_axis_tready <= 0;
					    state <= checkRequestType;
					end
			  end
			  checkRequestType: begin
			      // If tValid is not set, ignore this clock
			      if (s_ip_payload_axis_tvalid)
					begin
					   // ICMP Request Type is 08 00
					   if (s_ip_payload_axis_tdata == 8'h08)
						   state <= checkRequestCode;
						else
						   state <= idle;
					end
			  end
			  checkRequestCode: begin
			      // If tValid is not set, ignore this clock
			      if (s_ip_payload_axis_tvalid)
					begin
					   // ICMP Request Type is 08 00
					   if (s_ip_payload_axis_tdata == 8'h00)
						begin
						   local_storage_ptr <= 0;
							
							// Commands to Checksum Pipeline
							resetCs <= 0;
// Use this value for test purposes!!!							csStorage <= 16'h0800;
							csStorage <= 16'h0000;
							csCalcCsNow <= 1;
							
						   state <= delay1;
						end else
						begin
						   state <= idle;
						end
					end
			  end
			  delay1:
			       if (s_ip_payload_axis_tvalid)
			             state <= delay2;
			  delay2:
			       if (s_ip_payload_axis_tvalid)
			             state <= fillLocalStorage;
			  fillLocalStorage: begin
			       ram_addr_w <= local_storage_ptr;
			       ram_data_w <= s_ip_payload_axis_tdata;
					 ram_we <= s_ip_payload_axis_tvalid;
					 if (s_ip_payload_axis_tvalid)
					 begin
					      local_storage_ptr <= local_storage_ptr + 1; 
							
							csCalcCsNow <= ~csCalcCsNow;
							csStorage <= {csStorage[7:0],s_ip_payload_axis_tdata};
					 end
					 if (s_ip_payload_axis_tlast)
					 begin
					     state <= startTransmit;
					 end
			  end
			  startTransmit:
			  begin
			       ram_we <= 0;
					 ram_addr_r <= 0;
					 
					// We will save registers! That is why I will assign some output signals 
					// without lock. Hopefuloly, will no need change it for pipelining...
					m_ip_dest_ip <= s_ip_source_ip;
					m_ip_source_ip <= local_ip;
					m_ip_length <= s_ip_length; // For Ping it is true...
					m_ip_ttl <= s_ip_ttl;
					m_ip_hdr_valid <= 1;
			      state <= startTransmit2;
			  end
			  startTransmit2: begin
			      if (m_ip_hdr_ready)
					begin
					    m_ip_hdr_valid <= 0;
                   csForSend <= checksum [15:0] + checksum [19:16];

					    state <= sendFirstOctet00;
					end
			  
			  end
			 sendFirstOctet00: begin
			      if (m_ip_payload_axis_tready)
					begin
						csForSend <= ~csForSend;

					   m_ip_payload_axis_tdata <= 8'h00;
						m_ip_payload_axis_tvalid <= 1;
						
						state <= sendSecondOctet00;
						
					end
			 end
			 sendSecondOctet00: begin
			      if (m_ip_payload_axis_tready)
					begin

					   m_ip_payload_axis_tdata <= 8'h00;
						m_ip_payload_axis_tvalid <= 1;
						
						state <= sendFirstOctetCS;
						
					end
			 end
			 sendFirstOctetCS: begin
			      if (m_ip_payload_axis_tready)
					begin

					   m_ip_payload_axis_tdata <= csForSend[15:8];
						m_ip_payload_axis_tvalid <= 1;
						
						state <= sendSecondOctetCS;
						
					end
			 end
			 sendSecondOctetCS: begin
			      if (m_ip_payload_axis_tready)
					begin

					   m_ip_payload_axis_tdata <= csForSend [7:0];
						m_ip_payload_axis_tvalid <= 1;
						
						// We must keep pipeline in mind!
						local_storage_ptr <= local_storage_ptr - 1;
						ram_addr_r <= ram_addr_r + 1;
						
						state <= sendDataOctet;
						
					end
			 end
			 sendDataOctet:
			 begin
			      if (m_ip_payload_axis_tready)
					begin
					    m_ip_payload_axis_tdata <= ram_last_data_r;
						 ram_addr_r <= ram_addr_r + 1;
						 if (local_storage_ptr == 0)
						 begin
						     m_ip_payload_axis_tlast <= 1;
							  state <= qqq;
						 end else
						 begin
						     local_storage_ptr <= local_storage_ptr - 1;
					    end
					end
			 end
			 
			 qqq: begin
						 m_ip_payload_axis_tlast <= 0;
						 state <= idle;
			 end
			  
			  default: begin
	           state <= idle;
				  s_ip_payload_axis_tready <= 1;
			  end
		  endcase
	  end
end


endmodule
