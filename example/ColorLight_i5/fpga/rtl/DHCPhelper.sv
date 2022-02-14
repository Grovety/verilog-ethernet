module DHCPhelper#
(
    // target ("SIM", "GENERIC", "XILINX", "ALTERA")
    parameter TARGET = "GENERIC"
)
(
input                    rst,
input                    clk,

// Network parameters (initially, from EEPROM, then from DHCP)
output reg  [47:0]       local_mac,
output reg  [31:0]       local_ip,
output reg  [31:0]       gateway_ip,
output reg  [31:0]       subnet_mask,

// EEprom processing strobe/ack
input                    s_eeprom_process_start,
output  reg              s_eeprom_process_finished,
// EEProm AXIS channel for download Default Network Parameters
input       [7:0]        s_eeprom_axis_tdata,
input                    s_eeprom_axis_tvalid,
output   reg             s_eeprom_axis_tready,

input                    m_dhcp_discover_start,
output  reg              m_dhcp_discover_finished,
output  reg   [7:0]      m_dhcp_discover_axis_tdata,
output reg               m_dhcp_discover_axis_tvalid,
input                    m_dhcp_discover_axis_tready,
output reg               m_dhcp_discover_axis_last,

input                    s_dhcp_offer_start,
output  reg              s_dhcp_offer_finished,
input   [7:0]            s_dhcp_offer_axis_tdata,
input                    s_dhcp_offer_axis_tvalid,
output reg               s_dhcp_offer_axis_tready

);

reg  [8:0] filler_ptr;
wire [31:0] xid_online;
reg  [31:0] xid;

  prng prng_dhcp_xid_inst (
    .clk (clk),
    .rst (rst),
    .in  (1'b0),
    .res (xid_online)
  );
  
typedef enum {
                idle,
                fillFromEeprom1,fillFromEeprom2,
                fillDiscoverBlock1,fillDiscoverSendRequestedIp,fillDiscoverFinish,fillDiscoverTerminate,
                parseOfferBlock1
             } state_type;
state_type state;


always @(posedge clk)
begin
     if (rst)
     begin
       s_eeprom_axis_tready <= 0;
       s_eeprom_process_finished <= 0;
       m_dhcp_discover_finished <= 0;
       m_dhcp_discover_axis_last <= 0;
       state <= idle;
     end else
     begin
       case (state)
           idle: begin
              m_dhcp_discover_axis_last <= 0;
              s_eeprom_axis_tready <= 0;
              s_eeprom_process_finished <= 0;
              m_dhcp_discover_finished <= 0;
              if (s_eeprom_process_start)
              begin 
                  filler_ptr <= 0;
                  state <= fillFromEeprom1; 
              end else if (m_dhcp_discover_start)
              begin
                  filler_ptr <= 0;
                  xid <= xid_online;
                  state <= fillDiscoverBlock1;
              end else if (s_dhcp_offer_start)
              begin
                  filler_ptr <= 0;
                  state <= parseOfferBlock1;
              end
           end
           fillFromEeprom1: begin
             s_eeprom_axis_tready <= 1;
             if (s_eeprom_axis_tvalid)
             begin
						if (TARGET == "GENERIC") 
                  begin
                   case (filler_ptr[5:0])
                      6'd0: local_mac <= {local_mac[39:0],8'h02};
                      6'd1: local_mac <= {local_mac[39:0],8'h00};
                      6'd2: local_mac <= {local_mac[39:0],8'h00};
                      6'd3: local_mac <= {local_mac[39:0],8'h00};
                      6'd4: local_mac <= {local_mac[39:0],8'h00};
                      6'd5: local_mac <= {local_mac[39:0],8'h00};

                      6'd6: local_ip  <= {local_ip[23:0],8'd192};
                      6'd7: local_ip  <= {local_ip[23:0],8'd168};
                      6'd8: local_ip  <= {local_ip[23:0],8'd2};
                      6'd9: local_ip  <= {local_ip[23:0],8'd128};

                      6'd10: gateway_ip  <= {gateway_ip[23:0],8'd192};
                      6'd11: gateway_ip  <= {gateway_ip[23:0],8'd168};
                      6'd12: gateway_ip  <= {gateway_ip[23:0],8'd2};
                      6'd13: gateway_ip  <= {gateway_ip[23:0],8'd1};

                      6'd14: subnet_mask  <= {subnet_mask[23:0],8'd255};
                      6'd15: subnet_mask  <= {subnet_mask[23:0],8'd255};
                      6'd16: subnet_mask  <= {subnet_mask[23:0],8'd255};
                      6'd17: begin
                                    subnet_mask  <= {subnet_mask[23:0],8'd0};
                                    state <= fillFromEeprom2; 
                                    s_eeprom_process_finished <= 1;
                            end
						endcase
                end else begin
                   case (filler_ptr[5:0])
                      6'd0: local_mac <= {local_mac[39:0],s_eeprom_axis_tdata};
                      6'd1: local_mac <= {local_mac[39:0],s_eeprom_axis_tdata};
                      6'd2: local_mac <= {local_mac[39:0],s_eeprom_axis_tdata};
                      6'd3: local_mac <= {local_mac[39:0],s_eeprom_axis_tdata};
                      6'd4: local_mac <= {local_mac[39:0],s_eeprom_axis_tdata};
                      6'd5: local_mac <= {local_mac[39:0],s_eeprom_axis_tdata};

                      6'd6: local_ip  <= {local_ip[23:0],s_eeprom_axis_tdata};
                      6'd7: local_ip  <= {local_ip[23:0],s_eeprom_axis_tdata};
                      6'd8: local_ip  <= {local_ip[23:0],s_eeprom_axis_tdata};
                      6'd9: local_ip  <= {local_ip[23:0],s_eeprom_axis_tdata};

                      6'd10: gateway_ip  <= {gateway_ip[23:0],s_eeprom_axis_tdata};
                      6'd11: gateway_ip  <= {gateway_ip[23:0],s_eeprom_axis_tdata};
                      6'd12: gateway_ip  <= {gateway_ip[23:0],s_eeprom_axis_tdata};
                      6'd13: gateway_ip  <= {gateway_ip[23:0],s_eeprom_axis_tdata};

                      6'd14: subnet_mask  <= {subnet_mask[23:0],s_eeprom_axis_tdata};
                      6'd15: subnet_mask  <= {subnet_mask[23:0],s_eeprom_axis_tdata};
                      6'd16: subnet_mask  <= {subnet_mask[23:0],s_eeprom_axis_tdata};
                      6'd17: begin
                                    subnet_mask  <= {subnet_mask[23:0],s_eeprom_axis_tdata};
                                    state <= fillFromEeprom2; 
                                    s_eeprom_process_finished <= 1;
                            end
                  endcase
                  end
                  filler_ptr <= filler_ptr + 1;
             end   // if (s_eeprom_axis_tvalid)
           end  // fillFromEeprom1
           fillFromEeprom2: begin
                if (!s_eeprom_process_start)
                begin
                     s_eeprom_process_finished <= 0;
                     state <= idle;
                end
           end
           fillDiscoverBlock1: begin
               m_dhcp_discover_axis_tvalid <= 1;
               case (filler_ptr) 
                 9'h00: m_dhcp_discover_axis_tdata <= 8'h01;
                 9'h01: m_dhcp_discover_axis_tdata <= 8'h01;
                 9'h02: m_dhcp_discover_axis_tdata <= 8'h06;

                 9'h04: m_dhcp_discover_axis_tdata <= xid [31:24];
                 9'h05: m_dhcp_discover_axis_tdata <= xid [23:16];
                 9'h06: m_dhcp_discover_axis_tdata <= xid [15:8];
                 9'h07: m_dhcp_discover_axis_tdata <= xid [7:0];

                 9'h0a: m_dhcp_discover_axis_tdata <= local_ip [31:24];
                 9'h0b: m_dhcp_discover_axis_tdata <= local_ip [23:16];
                 9'h0c: m_dhcp_discover_axis_tdata <= local_ip [15:8];
                 9'h0d: m_dhcp_discover_axis_tdata <= local_ip [7:0];

                 9'h1c: m_dhcp_discover_axis_tdata <= local_mac [47:40];
                 9'h1d: m_dhcp_discover_axis_tdata <= local_mac [39:32];
                 9'h1e: m_dhcp_discover_axis_tdata <= local_mac [31:24];
                 9'h1f: m_dhcp_discover_axis_tdata <= local_mac [23:16];
                 9'h20: m_dhcp_discover_axis_tdata <= local_mac [15:8];
                 9'h21: m_dhcp_discover_axis_tdata <= local_mac [7:0];

                 // Magic Cookie DHCP
                 9'hec: m_dhcp_discover_axis_tdata <= 8'h63;
                 9'hed: m_dhcp_discover_axis_tdata <= 8'h82;
                 9'hee: m_dhcp_discover_axis_tdata <= 8'h53;
                 9'hef: m_dhcp_discover_axis_tdata <= 8'h63;

                 // Option 53 - Discovery
                 9'hf0: m_dhcp_discover_axis_tdata <= 8'h35;
                 9'hf1: m_dhcp_discover_axis_tdata <= 8'h01;
                 9'hf2: m_dhcp_discover_axis_tdata <= 8'h01;

                     default: m_dhcp_discover_axis_tdata <= 8'h00;
               endcase
               if (filler_ptr == 9'hf2)
               begin
                  state <= fillDiscoverSendRequestedIp;
                  filler_ptr <= 0;
               end else
               begin
                   filler_ptr <= filler_ptr + 1;
               end
           end
           fillDiscoverSendRequestedIp: begin
               case (filler_ptr) 
                 9'h00: m_dhcp_discover_axis_tdata <= 8'h32;
                 9'h01: m_dhcp_discover_axis_tdata <= 8'h04;
                 9'h02: m_dhcp_discover_axis_tdata <= local_ip [31:24];
                 9'h03: m_dhcp_discover_axis_tdata <= local_ip [23:16];
                 9'h04: m_dhcp_discover_axis_tdata <= local_ip [15:8];
                 9'h05: m_dhcp_discover_axis_tdata <= local_ip [7:0];
               endcase
               if (filler_ptr == 9'h05)
               begin
                  state <= fillDiscoverTerminate;
                  filler_ptr <= 0;
               end else
               begin
                  filler_ptr <= filler_ptr + 1;
               end
           end
           fillDiscoverTerminate: begin
               case (filler_ptr) 
                 9'h00: m_dhcp_discover_axis_tdata <= 8'hff;
                 default: m_dhcp_discover_axis_tdata <= 8'h00;
               endcase
               if (filler_ptr == 9'h04)
               begin
                  state <= fillDiscoverFinish;
                  filler_ptr <= 0;
                  m_dhcp_discover_axis_last <= 1;
               end else
               begin
                  filler_ptr <= filler_ptr + 1;
               end
           end
           fillDiscoverFinish: begin
               m_dhcp_discover_axis_last <= 0;
               m_dhcp_discover_axis_tvalid <= 0;
               m_dhcp_discover_finished <= 1;
               if (!m_dhcp_discover_start)
               begin
                   state <= idle;   
               end
           end
       endcase
     end
end

endmodule
