module SpiFlashReader
(
      input             rst,
      input             clk,

      input             read_strobe,
      input             write_strobe,
      input             erase_strobe,

      input [23:0]      start_addr,

      output reg        spi_sck,
      output reg        spi_mosi,
      input             spi_miso,
      output reg        spi_cs,

                // Data From EEPROM   
      output reg [7:0]  m_tdata,
      output reg        m_tvalid,
      input             m_tready,
                 
                // Data To EEPROM
      input [7:0]       s_tdata,
      input             s_tvalid,
      output reg        s_tready,
  
      output reg        finished
);


    typedef enum /*logic [4:0]*/ {idle,
                  sendByte2,sendByte3,sendByte4,sendByte5,
                  axisTx1,axisTx2,axisTx3,
                  transmitSpi,transmitSpi1,transmitSpi2,
                   Write_0,Write_1,Write_2,Write_3,Write_4,
                   Erase_0,Erase_1,Erase_2,Erase_3,Erase_4,
                   WaitWriteEnabled_0,WaitWriteEnabled_1,WaitWriteEnabled_2,WaitWriteEnabled_3,WaitWriteEnabled_4
                 } stateType;
    stateType state = idle;
    stateType returnState;
    stateType stateAfterWriteEnable;
    
    reg [7:0] dataForSpi;
    reg [3:0] bitCnt;
//    reg [3:0] timeOut;
    reg [3:0] delay;
    
    always @ (posedge clk)
    begin
       if (rst || ((read_strobe == 0) && (write_strobe==0)&& (erase_strobe==0)))
       begin
            state <= idle;
            spi_cs <= 1;
            spi_sck <= 0;
            spi_mosi <= 0;
            m_tvalid <= 0;
            s_tready <= 0;
            finished <= 0;
       end else
       begin
          case (state)
          idle: begin
             finished <= 0;
             s_tready <= 0;
             delay <= 4'hf;
//             timeOut <= 4'hf;
             if (read_strobe) 
             begin
               spi_cs <= 0;
               dataForSpi <= 8'h0b;
//               dataForSpi <= 8'h05;
               returnState <= sendByte2;
               state <= transmitSpi;
             end
             if (write_strobe) 
             begin
               spi_cs <= 0;
               dataForSpi <= 8'h06;  // Write Enable
               returnState <= WaitWriteEnabled_0;
               stateAfterWriteEnable <= Write_0;
               state <= transmitSpi;
             end
             if (erase_strobe) 
             begin
               spi_cs <= 0;
               dataForSpi <= 8'h06;  // Write Enable
               returnState <= WaitWriteEnabled_0;
               stateAfterWriteEnable <= Erase_0;
               state <= transmitSpi;
             end
          end
          sendByte2 : begin
               spi_cs <= 0;
               dataForSpi <= start_addr[23:16];
               returnState <= sendByte3;
               state <= transmitSpi;
          end
          sendByte3 : begin
               spi_cs <= 0;
               dataForSpi <= start_addr[15:8];
               returnState <= sendByte4;
               state <= transmitSpi;
          end
          sendByte4 : begin
               spi_cs <= 0;
               dataForSpi <= start_addr[7:0];
               returnState <= sendByte5;
               state <= transmitSpi;
          end
          sendByte5 : begin
               spi_cs <= 0;
               dataForSpi <= 8'h00;     // Dummy Byte
               returnState <= axisTx1;
               state <= transmitSpi;
          end
          axisTx1 : begin
               m_tvalid <= 0;
               spi_cs <= 0;
               dataForSpi <= 8'h00;
               returnState <= axisTx2;
               state <= transmitSpi;
          end
          axisTx2 : begin
               m_tdata <= dataForSpi;
               m_tvalid <= 1;
               state <= axisTx3;
          end
          axisTx3 : begin
               if (m_tready)
               begin
                   m_tvalid <= 0;
                   state <= axisTx1;
               end
          end
          transmitSpi: begin
             s_tready <= 0;
             bitCnt<= 7;
             spi_mosi <= dataForSpi [7];
             dataForSpi [7:0] <= {dataForSpi[6:0],spi_miso};
             state <= transmitSpi1;
          end
          transmitSpi1: begin
             spi_sck <= 1;
             state <= transmitSpi2;
          end
          transmitSpi2: begin
             spi_sck <= 0;
             dataForSpi [7:0] <= {dataForSpi[6:0],spi_miso};
             if (bitCnt == 4'd0)
             begin
                state <= returnState;
             end else
             begin
                bitCnt <= bitCnt - 1;
                spi_mosi <= dataForSpi [7];
                state <= transmitSpi1;
             end
          end
          Write_0: begin
               spi_cs <= 0;
               dataForSpi <= 8'h02;  // Page Program
               returnState <= Write_1;
               state <= transmitSpi;
          end
          Write_1 : begin
               dataForSpi <= start_addr[23:16];
               returnState <= Write_2;
               state <= transmitSpi;
          end
          Write_2 : begin
               dataForSpi <= start_addr[15:8];
               returnState <= Write_3;
               state <= transmitSpi;
          end
          Write_3 : begin
               dataForSpi <= start_addr[7:0];
               returnState <= Write_4;
               state <= transmitSpi;
          end
          Write_4: begin
               if (s_tvalid)
               begin
                    dataForSpi <= s_tdata;
                    s_tready <= 1;
                    returnState <= Write_4;
                    state <= transmitSpi;
               end else 
               begin
                    spi_cs <= 1;
               end
          end
          Erase_0: begin
               spi_cs <= 0;
//               dataForSpi <= 8'h52;  // Block Erase 32K
               dataForSpi <= 8'h20;  // Block Erase 4K
               returnState <= Erase_1;
               state <= transmitSpi;
          end
          Erase_1 : begin
               dataForSpi <= start_addr[23:16];
               returnState <= Erase_2;
               state <= transmitSpi;
          end
          Erase_2 : begin
               dataForSpi <= start_addr[15:8];
               returnState <= Erase_3;
               state <= transmitSpi;
          end
          Erase_3 : begin
               dataForSpi <= start_addr[7:0];
               returnState <= Erase_4;
               state <= transmitSpi;
          end
          Erase_4 : begin
             finished <= 1;
          end
          WaitWriteEnabled_0: begin
               spi_cs <= 1;
               if (delay[0] | delay[1] | delay[2] | delay[3])
               begin
                   delay <= delay - 1;
               end else
               begin 
                    state <= WaitWriteEnabled_1;
               end 
          end

          WaitWriteEnabled_1: begin
               spi_cs <= 0;
               dataForSpi <= 8'h05;  // Write Enable
               returnState <= WaitWriteEnabled_2;
               state <= transmitSpi;
          end

          WaitWriteEnabled_2: begin
               dataForSpi <= 8'h00; 
               returnState <= WaitWriteEnabled_3;
               state <= transmitSpi;
          end
          WaitWriteEnabled_3: begin
              spi_cs <= 1;
              delay <= 4'hf;
//              if ((dataForSpi [1] & (!dataForSpi [0])) || (!(timeOut[0] | timeOut[1] | timeOut[2] | timeOut[3])))
              if (dataForSpi [1] & (!dataForSpi [0])) 
              begin
                  state <= WaitWriteEnabled_4;
              end  else
              begin
//                  timeOut <= timeOut - 1;
                  state <= WaitWriteEnabled_0;
              end
          end
          WaitWriteEnabled_4: begin
               if (delay[0] | delay[1] | delay[2] | delay[3])
               begin
                   delay <= delay - 1;
               end else
               begin 
                    state <= stateAfterWriteEnable;
               end 
          end
          endcase
       end
    end


endmodule
