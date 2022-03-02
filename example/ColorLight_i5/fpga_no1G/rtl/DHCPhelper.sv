module DHCPhelper#
(
    // target ("SIM", "GENERIC", "XILINX", "ALTERA")
    parameter TARGET = "GENERIC"
)
(
input                    rst,
input                    clk,
input                    clk25,

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
input                    m_dhcp_discover_step_request,   // 1 - DHCPDISCOVER, 0 - DHCPREQUEST
output  reg   [7:0]      m_dhcp_discover_axis_tdata,
output reg               m_dhcp_discover_axis_tvalid,
input                    m_dhcp_discover_axis_tready,
output reg               m_dhcp_discover_axis_last,

input                    s_dhcp_offer_start,
output reg               s_dhcp_offer_finished,
input   [7:0]            s_dhcp_offer_axis_tdata,
input                    s_dhcp_offer_axis_tvalid,
output                   s_dhcp_offer_axis_tready,
input                    s_dhcp_offer_axis_tlast,

//output reg [7:0]         dhcp_lastAnswerType,

output reg  [31:0]       remain_lease_time,
output reg               halfLeaseTimerIsReached,


output reg               dhcp_offerIsReceived,
output [15:0]            dbg_out

);

reg  [7:0] filler_ptr;
reg  [7:0] parser_ptr;
reg  [4:0] option_ptr;
reg  [7:0] option_id;
reg  [5:0] option_len;
reg  [31:0] option_data;
wire [31:0] xid_online;
reg  [31:0] xid;

reg  [31:0]       temp_ip;
reg  [31:0]       online_ip;
reg  [31:0]       temp_gateway_ip;
reg               temp_gateway_ip_is_filled;
reg  [31:0]       temp_subnet_mask;
reg  [31:0]       temp_lease_time;
reg  [31:0]       temp_option_54;
reg               temp_option_54_is_filled;
reg               clr_fifo;

// For clock domain crossing!
reg dhcp_offer_finished;
reg dhcp_offer_finished1;
reg dhcp_offer_finished2;

reg need_latch_parameters_1;
reg need_latch_parameters_2;
reg need_latch_parameters;

always @ (posedge clk)
begin
     dhcp_offer_finished1 <= dhcp_offer_finished;
     dhcp_offer_finished2 <= dhcp_offer_finished1;
     s_dhcp_offer_finished <= dhcp_offer_finished2;

     need_latch_parameters_2 <= need_latch_parameters_1;
     need_latch_parameters <= need_latch_parameters_2;
end

reg dhcp_offer_start1;
reg dhcp_offer_start2;
reg dhcp_offer_start;
reg parameters_latched;
reg parameters_latched1;
reg parameters_latched2;

always @ (posedge clk25)
begin
     dhcp_offer_start1 <= s_dhcp_offer_start;
     dhcp_offer_start2 <= dhcp_offer_start1;
     dhcp_offer_start <= dhcp_offer_start2;
     
     parameters_latched2 <= parameters_latched1;
     parameters_latched <= parameters_latched2;
end



reg [13:0] remain_timer_1;
reg [13:0] remain_timer_2;


always @(posedge clk)
begin
     if (rst)
     begin
        remain_timer_1 <= 0;
        remain_timer_2 <= 0;
     end else
     begin
        if (need_latch_parameters)
        begin
            remain_lease_time <= temp_lease_time;
            halfLeaseTimerIsReached <= 0;
        end else
        begin
           if (remain_timer_1 == 0) 
           begin
              remain_timer_1 <= 10417;		// Change to parameter later!!!
              if (remain_timer_2 == 0)
              begin
                    remain_timer_2 <= 10000;       // Also change to parameter later!!!
                    if (remain_lease_time != 0)
                    begin
                        remain_lease_time <= remain_lease_time -1;
                    end
              end else
              begin
                   remain_timer_2 <= remain_timer_2 - 1;
              end
           end else
           begin
             if (remain_lease_time == {0,temp_lease_time [31:1]})
             begin
                 halfLeaseTimerIsReached <= 1;
             end
             remain_timer_1 <= remain_timer_1 - 1;
           end
        end
     end

end

always @(posedge clk)
begin
      if (rst)
      begin

      end else
      begin
      end
end

generate
if (TARGET == "GENERIC") 
     assign xid_online = 32'h12345678;
else
  prng prng_dhcp_xid_inst (
    .clk (clk),
    .rst (rst),
    .in  (1'b0),
    .res (xid_online)
  );
endgenerate

wire [7:0] dhcp_offer_axis_tdata;
wire       dhcp_offer_axis_tvalid;
reg        dhcp_offer_axis_tready;
wire       dhcp_offer_axis_tlast;

axis_async_fifo  #(
    .DEPTH(512),
    .ID_ENABLE(0),
    .DEST_ENABLE(0),
    .USER_ENABLE(1),
    .USER_WIDTH(1),
    .FRAME_FIFO(0)
)fifo
(
    // Common reset
    .async_rst(rst|clr_fifo),
    // AXI input
    .s_clk(clk),
    .s_axis_tdata (s_dhcp_offer_axis_tdata),
    .s_axis_tvalid(s_dhcp_offer_axis_tvalid),
    .s_axis_tready(s_dhcp_offer_axis_tready),
    .s_axis_tlast (s_dhcp_offer_axis_tlast),
    .s_axis_tid(0),
    .s_axis_tdest(0),
    .s_axis_tuser(0),
    // AXI output
    .m_clk(clk25),
    .m_axis_tdata(dhcp_offer_axis_tdata),
//    .m_axis_tkeep(),
    .m_axis_tvalid(dhcp_offer_axis_tvalid),
    .m_axis_tready(dhcp_offer_axis_tready),
    .m_axis_tlast(dhcp_offer_axis_tlast)
);

assign dbg_out [7:0] = s_dhcp_offer_axis_tdata;
assign dbg_out [8] = s_dhcp_offer_axis_tvalid;
assign dbg_out [9] = s_dhcp_offer_axis_tready;
assign dbg_out [10] = s_dhcp_offer_axis_tlast;
//assign dbg_out [15] = clk;
assign dbg_out [11] = dhcp_offer_axis_tdata[0];
assign dbg_out [12] = dhcp_offer_axis_tdata[1];
assign dbg_out [13] = dhcp_offer_axis_tready;

ODDRX1F ODDRX1Fdd(
	.D0(1'd1),
	.D1(1'd0),
	.SCLK(clk25),
	.Q(dbg_out[14])
);
ODDRX1F ODDRX1Fd(
	.D0(1'd1),
	.D1(1'd0),
	.SCLK(clk),
	.Q(dbg_out[15])
);


/*assign dbg_out [7:0] = dhcp_offer_axis_tdata;
assign dbg_out [8] = dhcp_offer_axis_tvalid;
assign dbg_out [9] = dhcp_offer_axis_tready;
assign dbg_out [10] = dhcp_offer_axis_tlast;
assign dbg_out [15] = clk25;*/

  
typedef enum {
                idle,
                fillFromEeprom1,fillFromEeprom2,
                fillDiscoverBlock1,fillDiscoverSendOption03,fillDiscoverSendOption50,fillDiscoverSendOption54,
                fillDiscoverFinish,fillDiscoverTerminate
             } state_type_filler;
state_type_filler state_filler;


always @(posedge clk)
begin
     if (rst)
     begin
       s_eeprom_axis_tready <= 0;
       s_eeprom_process_finished <= 0;
       m_dhcp_discover_finished <= 0;
       m_dhcp_discover_axis_last <= 0;
       state_filler <= idle;
     end else
     begin
       case (state_filler)
           idle: begin
              if (need_latch_parameters)
              begin
                    parameters_latched1 <= 1;
                    local_ip <= temp_ip;
                    gateway_ip <= temp_gateway_ip;
                    subnet_mask <= temp_subnet_mask;
              end else 
              begin
                   parameters_latched1 <= 0;
              end
              m_dhcp_discover_axis_last <= 0;
              s_eeprom_axis_tready <= 0;
              s_eeprom_process_finished <= 0;
              m_dhcp_discover_finished <= 0;
              if (s_eeprom_process_start)
              begin 
                  filler_ptr <= 0;
                  state_filler <= fillFromEeprom1; 
              end else if (m_dhcp_discover_start)
              begin
                  filler_ptr <= 0;
                  if (m_dhcp_discover_step_request)
                  begin
                       xid <= xid_online; 
                       online_ip <= local_ip;
                  end else
                  begin
                       online_ip <= temp_ip;
                  end
                  state_filler <= fillDiscoverBlock1;
              end
           end
           fillFromEeprom1: begin
             s_eeprom_axis_tready <= 1;
             if (s_eeprom_axis_tvalid)
             begin
//                  if (TARGET == "GENERIC") 
                   if (TARGET == "LATTICE")     // This is emergency line for uncomment it in case of damaged EEPROM content. 
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
                                    state_filler <= fillFromEeprom2; 
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
                                    state_filler <= fillFromEeprom2; 
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
                     state_filler <= idle;
                end
           end
           fillDiscoverBlock1: begin
               m_dhcp_discover_axis_tvalid <= 1;
               case (filler_ptr) 
                 8'h00: m_dhcp_discover_axis_tdata <= 8'h01;
                 8'h01: m_dhcp_discover_axis_tdata <= 8'h01;
                 8'h02: m_dhcp_discover_axis_tdata <= 8'h06;

                 8'h04: m_dhcp_discover_axis_tdata <= xid [31:24];
                 8'h05: m_dhcp_discover_axis_tdata <= xid [23:16];
                 8'h06: m_dhcp_discover_axis_tdata <= xid [15:8];
                 8'h07: m_dhcp_discover_axis_tdata <= xid [7:0];

                 8'h0c: m_dhcp_discover_axis_tdata <= m_dhcp_discover_step_request?local_ip [31:24]:8'h00;
                 8'h0d: m_dhcp_discover_axis_tdata <= m_dhcp_discover_step_request?local_ip [23:16]:8'h00;
                 8'h0e: m_dhcp_discover_axis_tdata <= m_dhcp_discover_step_request?local_ip [15:8]:8'h00;
                 8'h0f: m_dhcp_discover_axis_tdata <= m_dhcp_discover_step_request?local_ip [7:0]:8'h00;

                 8'h1c: m_dhcp_discover_axis_tdata <= local_mac [47:40];
                 8'h1d: m_dhcp_discover_axis_tdata <= local_mac [39:32];
                 8'h1e: m_dhcp_discover_axis_tdata <= local_mac [31:24];
                 8'h1f: m_dhcp_discover_axis_tdata <= local_mac [23:16];
                 8'h20: m_dhcp_discover_axis_tdata <= local_mac [15:8];
                 8'h21: m_dhcp_discover_axis_tdata <= local_mac [7:0];

                 8'h40: m_dhcp_discover_axis_tdata <= remain_lease_time [31:24];
                 8'h41: m_dhcp_discover_axis_tdata <= remain_lease_time [23:16];
                 8'h42: m_dhcp_discover_axis_tdata <= remain_lease_time [15:8];
                 8'h43: m_dhcp_discover_axis_tdata <= remain_lease_time [7:0];
                 8'h44: m_dhcp_discover_axis_tdata <= {7'b1010101,halfLeaseTimerIsReached};

                 // Magic Cookie DHCP
                 8'hec: m_dhcp_discover_axis_tdata <= 8'h63;
                 8'hed: m_dhcp_discover_axis_tdata <= 8'h82;
                 8'hee: m_dhcp_discover_axis_tdata <= 8'h53;
                 8'hef: m_dhcp_discover_axis_tdata <= 8'h63;

                 // Option 53 - Discovery
                 8'hf0: m_dhcp_discover_axis_tdata <= 8'h35;
                 8'hf1: m_dhcp_discover_axis_tdata <= 8'h01;
                 8'hf2: m_dhcp_discover_axis_tdata <= m_dhcp_discover_step_request?8'h01:8'h03;

                     default: m_dhcp_discover_axis_tdata <= 8'h00;
               endcase
               if (filler_ptr == 8'hf2)
               begin
                  if ((temp_gateway_ip_is_filled) && (!m_dhcp_discover_step_request))
                      state_filler <= fillDiscoverSendOption03;
                  else
                      state_filler <= fillDiscoverSendOption50;
                  filler_ptr <= 0;
               end else
               begin
                   filler_ptr <= filler_ptr + 1;
               end
           end
           fillDiscoverSendOption03: begin
               case (filler_ptr) 
                 8'h00: m_dhcp_discover_axis_tdata <= 8'h03;
                 8'h01: m_dhcp_discover_axis_tdata <= 8'h04;
                 8'h02: m_dhcp_discover_axis_tdata <= temp_gateway_ip [31:24];
                 8'h03: m_dhcp_discover_axis_tdata <= temp_gateway_ip [23:16];
                 8'h04: m_dhcp_discover_axis_tdata <= temp_gateway_ip [15:8];
                 8'h05: m_dhcp_discover_axis_tdata <= temp_gateway_ip [7:0];
               endcase
               if (filler_ptr == 8'h05)
               begin
                  state_filler <= fillDiscoverSendOption50;
                  filler_ptr <= 0;
               end else
               begin
                  filler_ptr <= filler_ptr + 1;
               end
           end
           fillDiscoverSendOption50: begin
               case (filler_ptr) 
                 8'h00: m_dhcp_discover_axis_tdata <= 8'd50;
                 8'h01: m_dhcp_discover_axis_tdata <= 8'h04;
                 8'h02: m_dhcp_discover_axis_tdata <= online_ip [31:24];
                 8'h03: m_dhcp_discover_axis_tdata <= online_ip [23:16];
                 8'h04: m_dhcp_discover_axis_tdata <= online_ip [15:8];
                 8'h05: m_dhcp_discover_axis_tdata <= online_ip [7:0];
               endcase
               if (filler_ptr == 8'h05)
               begin
                  if ((temp_option_54_is_filled) && (!m_dhcp_discover_step_request))
                      state_filler <= fillDiscoverSendOption54;
                  else
                      state_filler <= fillDiscoverTerminate;
                  filler_ptr <= 0;
               end else
               begin
                  filler_ptr <= filler_ptr + 1;
               end
           end
           fillDiscoverSendOption54: begin
               case (filler_ptr) 
                 8'h00: m_dhcp_discover_axis_tdata <= 8'd54;
                 8'h01: m_dhcp_discover_axis_tdata <= 8'h04;
                 8'h02: m_dhcp_discover_axis_tdata <= temp_option_54 [31:24];
                 8'h03: m_dhcp_discover_axis_tdata <= temp_option_54 [23:16];
                 8'h04: m_dhcp_discover_axis_tdata <= temp_option_54 [15:8];
                 8'h05: m_dhcp_discover_axis_tdata <= temp_option_54 [7:0];
               endcase
               if (filler_ptr == 8'h05)
               begin
                  state_filler <= fillDiscoverTerminate;
                  filler_ptr <= 0;
               end else
               begin
                  filler_ptr <= filler_ptr + 1;
               end
           end
           fillDiscoverTerminate: begin
               case (filler_ptr) 
                 8'h00: m_dhcp_discover_axis_tdata <= 8'hff;
                 default: m_dhcp_discover_axis_tdata <= 8'h00;
               endcase
               if (filler_ptr == 8'h04)
               begin
                  state_filler <= fillDiscoverFinish;
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
                   state_filler <= idle;   
               end
           end
       endcase
     end
end

typedef enum {
                parseIdle,
                parseOfferBlock1,parseOfferProcessOption1,parseOfferProcessOption2,
                   parseOfferProcessOption3,parseLatchParameters,parseLatchParameters2,parseOfferWaitFinish
             } state_type_parser;
state_type_parser state_parser;

always @(posedge clk25/* or posedge rst*/)
begin
     if (rst | (~dhcp_offer_start))
     begin
       dhcp_offer_axis_tready <= 0;
       dhcp_offer_finished <= 0;
       state_parser <= parseIdle;
       clr_fifo <= 0;
     end else
     begin
       case (state_parser)
           parseIdle: begin
              clr_fifo <= 0;
              dhcp_offer_axis_tready <= 0;
              dhcp_offer_finished <= 0;
              if (dhcp_offer_start)
              begin
                  parser_ptr <= 0;
                  state_parser <= parseOfferBlock1;
                  // We must clear those flags exactly here
                  // because received packed can either contain
                  // those options or not contain
                  temp_gateway_ip_is_filled <= 0;
                  temp_option_54_is_filled <= 0;
              end
           end
           parseOfferBlock1: begin
              dhcp_offer_axis_tready <= 1;
              if (dhcp_offer_axis_tvalid)
              begin
                 case (parser_ptr)
                     8'h00: if (dhcp_offer_axis_tdata != 8'h02) state_parser <= parseOfferWaitFinish;
                     8'h01: if (dhcp_offer_axis_tdata != 8'h01) state_parser <= parseOfferWaitFinish;
                     8'h02: if (dhcp_offer_axis_tdata != 8'h06) state_parser <= parseOfferWaitFinish;

                     8'h04: if (dhcp_offer_axis_tdata != xid [31:24]) state_parser <= parseOfferWaitFinish;
                     8'h05: if (dhcp_offer_axis_tdata != xid [23:16]) state_parser <= parseOfferWaitFinish;
                     8'h06: if (dhcp_offer_axis_tdata != xid [15:8]) state_parser <= parseOfferWaitFinish;
                     8'h07: if (dhcp_offer_axis_tdata != xid [7:0]) state_parser <= parseOfferWaitFinish;

                     8'h10: temp_ip [31:24] <= dhcp_offer_axis_tdata;
                     8'h11: temp_ip [23:16] <= dhcp_offer_axis_tdata;
                     8'h12: temp_ip [15:8] <= dhcp_offer_axis_tdata;
                     8'h13: temp_ip [7:0] <= dhcp_offer_axis_tdata;
                     8'hef: begin
                                 state_parser <= parseOfferProcessOption1;
                                 option_ptr <= 0;
                            end
                 endcase
                 parser_ptr <= parser_ptr + 1;
              end
           end
           parseOfferProcessOption1: begin
              if (dhcp_offer_axis_tvalid)
              begin
                  option_id <= dhcp_offer_axis_tdata;
                  if ((dhcp_offer_axis_tdata == 8'hff) || (dhcp_offer_axis_tlast == 1))
                  begin
                       state_parser <= parseLatchParameters;
                  end else
                  begin
                       state_parser <= parseOfferProcessOption2;
                  end
              end
           end
           parseOfferProcessOption2: begin
              if (dhcp_offer_axis_tvalid)
              begin
                  option_len <= dhcp_offer_axis_tdata[5:0];
                  if ((dhcp_offer_axis_tdata[5:0] == 0)|| (dhcp_offer_axis_tlast == 1))
                  begin
                       state_parser <= parseLatchParameters;
                  end else
                  begin
                       state_parser <= parseOfferProcessOption3;
                  end
              end
           end
           parseOfferProcessOption3: begin
              if (dhcp_offer_axis_tlast)
              begin 
                 state_parser <= parseLatchParameters;
              end else
              begin
                if (dhcp_offer_axis_tvalid)
                begin
                  if (option_len == 6'h01)
                  begin
                     case (option_id)

                        8'd1: begin
//                                 dhcp_lastAnswerType <= dhcp_offer_axis_tdata;
                                 temp_subnet_mask <= {option_data [23:0],dhcp_offer_axis_tdata};
                                 state_parser <= parseOfferProcessOption1;
                               end
                        8'd3: begin
//                                 dhcp_lastAnswerType <= dhcp_offer_axis_tdata;
                                 temp_gateway_ip <= {option_data [23:0],dhcp_offer_axis_tdata};
                                 state_parser <= parseOfferProcessOption1;
                                 temp_gateway_ip_is_filled <= 1;
                               end
                        8'd51: begin
//                                 dhcp_lastAnswerType <= dhcp_offer_axis_tdata;
                                 temp_lease_time <= {option_data [23:0],dhcp_offer_axis_tdata};
                                 state_parser <= parseOfferProcessOption1;
                               end
                        8'd53: begin
//                                 dhcp_lastAnswerType <= dhcp_offer_axis_tdata;
                                 dbg_ustas_to_alex <= dhcp_offer_axis_tdata;
                                 dbg_ustas_to_alex_cnt <= dbg_ustas_to_alex_cnt + 1;
                                 if (dhcp_offer_axis_tdata == 8'h02)
                                     dhcp_offerIsReceived <= 1;
                                 else
                                     dhcp_offerIsReceived <= 0;
//                                 dhcp_offerIsReceived <= (dhcp_offer_axis_tdata == 8'h02)?1:0; 
                                 state_parser <= parseOfferProcessOption1;
                               end
                        8'd54:  begin
                                 temp_option_54 <= {option_data [23:0],dhcp_offer_axis_tdata};
                                 state_parser <= parseOfferProcessOption1;
                                 temp_option_54_is_filled <= 1;
                               end
                        8'hff : state_parser <= parseLatchParameters;
                        default: state_parser <= parseOfferProcessOption1;
                     endcase
                    end else 
                    begin
                       option_len <= option_len - 1;
                    end
                  option_data <= {option_data [23:0],dhcp_offer_axis_tdata};
               end
             end
           end
           parseLatchParameters: begin
               if ((!temp_gateway_ip_is_filled) && (!temp_option_54_is_filled))
               begin 
                 state_parser <= parseOfferWaitFinish;
               end else
               begin
                    if (!temp_gateway_ip_is_filled)
                    begin
                        temp_gateway_ip <= temp_option_54;
                    end
                    state_parser <= parseLatchParameters2;
               end    
           end
           parseLatchParameters2: begin
              if (parameters_latched)
              begin
                  need_latch_parameters_1 <= 0;
                  state_parser <= parseOfferWaitFinish;
              end else
              begin
                  need_latch_parameters_1 <= 1;
              end
           end
           parseOfferWaitFinish: begin
               dhcp_offer_finished <= 1;
               dhcp_offer_axis_tready <= 0;
               clr_fifo <= 1;
               if (dhcp_offer_start == 0)
               begin
                    state_parser <= parseIdle;
               end
           end
       endcase
     end
end
endmodule
