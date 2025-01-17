module mdio_control #(parameter BaudRateDivider = 1085) (
    input              clk125,
    input              reset,
    input              rxd,
    output reg         txd = 0,

    output reg  [3:0]  control = 0,

    output wire        mdc_o,
    input  wire        mdio_i,
    output wire        mdio_o,
    output wire        mdio_t

);

wire mdioBusy;
wire mdioCmdReady;
reg mdioCmdValid = 0;
wire mdioDataOutReady;
wire [15:0] mdioDataOut;

reg [15:0] txShift = 0;
reg [4:0] txBit = 0;
reg [12:0] txDelay = 0;
reg txReady = 0;

reg rxd1;
always @(posedge clk125) begin
    rxd1 <= rxd;
end

// Tx State Machine no needs any state :-)
// Bit Number is the best state for it!!!
always @(posedge clk125) begin
    if (reset == 1) begin
    end else begin
        txReady <= 0;    
        if (txDelay != 0) begin
            txDelay <= txDelay - 1;
        end
        else begin
            if (txBit == 20) begin
                txReady <= 1;
                if (mdioDataOutReady == 1) begin
                    txShift <= mdioDataOut;
                    txBit <= 0;
                end
            end else begin
                txReady <= 0;
                if ((txBit == 0) || (txBit == 10)) begin
                    txd <= 0;  
                end else if ((txBit == 9) || (txBit == 19)) begin
                        txd <= 1;
                end else begin
                    txd <= txShift [0];
                    txShift <= {1'b0,txShift[15:1]};
                end
                txBit <= txBit + 1;
                txDelay <= BaudRateDivider;
            end
        end
    end
end

reg [31:0] rxShift = 0;
reg [23:0] rxDelay = 0;
reg [3:0] rxBit = 0;
reg [2:0] rxByte;

localparam rxIdle                           = 0;
localparam rxStart                          = 1;
localparam rxData                           = 2;
localparam rxStop                           = 3;
localparam rxWaitForNextByte                = 4;
localparam rxProcessingCmd                  = 5;

reg [3:0] rxState = rxIdle;

always @(posedge clk125) begin
    if (reset == 1) begin 
        rxState = rxIdle; 
        mdioCmdValid <= 0;
    end else begin
        case (rxState)
            rxIdle: begin
                rxByte <= 4;
                mdioCmdValid <= 0;
                if (rxd1 == 0) begin
                    rxState <= rxStart;
                    rxDelay <= (BaudRateDivider / 2)-1;
                end
            end
            rxStart: begin
                if (rxDelay == 0) begin
                    debug <= !debug;
                    rxState <= rxData;
                    rxDelay <= BaudRateDivider-1;
                    rxBit <= 8;
                end else begin
                    rxDelay <= rxDelay - 1;
                end
            end
            rxData: begin
                if (rxDelay == 0) begin 
                    debug <= !debug;
                    if (rxBit == 0) begin
                        rxByte <= rxByte - 1;
                        rxState <= rxStop;
                        rxDelay <= 1;
                    end else begin
                        rxShift <= {rxd1,rxShift[31:1]};
                        rxBit <= rxBit - 1;
                        rxDelay <= BaudRateDivider-1;
                    end
                end else begin
                    rxDelay <= rxDelay - 1;
                end
            end
            rxStop: begin
                if (rxDelay == 0) begin
                    debug <= !debug;
                    if (rxByte == 0) begin
                        rxState <= rxProcessingCmd;
                    end else begin
                        rxState <= rxWaitForNextByte;
                        rxDelay <= 24'hffffff;
                    end
                end else begin
                    rxDelay <= rxDelay - 1;
                end
            end
            rxWaitForNextByte: begin
                if (rxDelay == 0) begin
                    rxState <= rxIdle;
                end else begin
                    if (rxd1 == 0) begin
                        rxState <= rxStart;
                        rxDelay <= (BaudRateDivider / 2)-1;
                    end else begin
                        rxDelay <= rxDelay - 1;
                    end
                end
            end
            rxProcessingCmd: begin
                if (mdioCmdReady == 1) begin
                    mdioCmdValid <= 1;
                    rxState <= rxIdle;
                end
                control <= rxShift [13:10];
            end
            default: begin
                rxState <= rxIdle;
            end
        endcase
    end
end

mdio_master mdio_phy (
    .clk(clk125),
    .rst(reset),
    /*
     * Host interface
     */
    .cmd_phy_addr(rxShift[4:0]),
    .cmd_reg_addr(rxShift[9:5]),
    .cmd_data(rxShift[31:16]),
    .cmd_opcode(rxShift[15:14]),
    .cmd_valid(mdioCmdValid),
    .cmd_ready(mdioCmdReady),

    .data_out(mdioDataOut),
    .data_out_valid(mdioDataOutReady),
    .data_out_ready(txReady),
    /*
     * MDIO to PHY
     */
    .mdc_o(mdc_o),
    .mdio_i(mdio_i),
    .mdio_o(mdio_o),
    .mdio_t(mdio_t),
    /*
     * Status
     */
    .busy(mdioBusy),
    /*
     * Configuration
     */
    .prescale(8'h10)
);

endmodule
