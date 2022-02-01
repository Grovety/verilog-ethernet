module SpiFlashReader
(
		input             rst,
		input             clk,

                input             read_strobe,
                input             write_strobe,

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
		output reg        s_tready
);


    typedef enum {idle,
	               sendByte2,sendByte3,sendByte4,sendByte5,
						axisTx1,axisTx2,axisTx3,
						transmitSpi,transmitSpi1,transmitSpi2} stateType;
	 stateType state;
	 stateType returnState;
	 
    reg [7:0] dataForSpi;
    reg [3:0] bitCnt;
	 
    always @ (posedge clk)
	 begin
	    if (rst || ((read_strobe == 0) && (write_strobe==0)))
		 begin
			 state <= idle;
			 spi_cs <= 1;
			 spi_sck <= 0;
			 spi_mosi <= 0;
			 m_tvalid <= 0;
                         s_tready <= 0;
	    end else
		 begin
		    case (state)
			 idle: begin
                             if (read_strobe) 
                             begin
			         spi_cs <= 0;
				 dataForSpi <= 8'h0b;
			         returnState <= sendByte2;
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
			     
			 endcase
		 end
	 end


endmodule
