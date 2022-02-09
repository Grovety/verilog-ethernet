module DHCPhelper
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
outoput reg              m_dhcp_discover_axis_tvalid,
input                    m_dhcp_discover_axis_tready
);

typedef enum {
                idle,
                fillFromEeprom1,fillFromEeprom2,
                fillDiscoverBlock1
             } state_type;
state_type state;
reg [8:0] filler_ptr;

always @(posedge clk)
begin
     if (rst)
     begin
       s_eeprom_axis_tready <= 0;
       s_eeprom_process_finished <= 0;
       m_dhcp_discover_finished <= 0;
       state <= idle;
     end else
     begin
       case (state)
           idle: begin
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
                  state <= fillDiscoverBlock1;
              end
           end
           fillFromEeprom1: begin
             s_eeprom_axis_tready <= 1;
             if (s_eeprom_axis_tvalid)
             begin
                  case (filler_ptr)
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
                     0: m_dhcp_discover_axis_tdata <= 8'h01;
                     1: m_dhcp_discover_axis_tdata <= 8'h01;
                     2: m_dhcp_discover_axis_tdata <= 8'h06;
                     default: m_dhcp_discover_axis_tdata <= 8'h00;
               endcase
               if (filler_ptr == 9'heb)
               begin
                  state <= fillDiscoverBlock2;
               end
           end
           fillDiscoverBlock2: begin
               m_dhcp_discover_axis_tvalid <= 0;    // Kill Me!
               state <= idle;   
           end
       endcase
     end
end

endmodule
