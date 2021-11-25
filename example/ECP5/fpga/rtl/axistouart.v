module axistouart
#(parameter BaudRateDivider = 1085)
(
      input clk125,
      input reset,

      output reg txd = 0,

      input [7:0] axis_tdata,
      input       axis_valid,
      output reg  axis_tready = 0
);

reg [7:0] txShift = 0;
reg [4:0] txBit = 0;
reg [12:0] txDelay = 0;

// Tx State Machine no needs any state :-)
// Bit Number is the best state for it!!!
always @(posedge clk125)
begin
   axis_tready <= 0;
   if (reset == 1)
   begin
         txBit <= 11 ;
   end else
   begin 
        if (txDelay != 0)
              txDelay <= txDelay - 1;
        else begin
             if (txBit == 11)
             begin
                  if (axis_valid == 1)
                  begin
                       axis_tready <= 1;
                       txShift <= axis_tdata;
                       txBit <= 0;
                  end
             end else
             begin
//                  axis_tready <= 0;
                  if (txBit == 0)
                     txd <= 0;  
                  else if ((txBit == 9)||(txBit == 10))
                     txd <= 1;
                  else begin
                     txd <= txShift [0];
                     txShift <= {1'b0,txShift[7:1]};
                  end
                  txBit <= txBit + 1;
                  txDelay <= BaudRateDivider;
             end
        end
   end
end
endmodule