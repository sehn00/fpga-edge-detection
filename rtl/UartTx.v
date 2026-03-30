`timescale 1ns/1ps

module UartTx #(
    parameter CLK_FREQ = 75_000_000,
    parameter BAUD     = 2000000
)(
    input  wire       iClk,
    input  wire       iRsn,
    input  wire       iTxStart,
    input  wire [7:0] iTxData,
    output reg        oTxBusy,
    output reg        oTx
);

localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD;

localparam [1:0] S_IDLE  = 2'd0;
localparam [1:0] S_START = 2'd1;
localparam [1:0] S_DATA  = 2'd2;
localparam [1:0] S_STOP  = 2'd3;

reg [1:0]  rState;
reg [15:0] rClkCnt;
reg [2:0]  rBitIdx;
reg [7:0]  rShiftReg;

always @(posedge iClk) begin
    if (!iRsn) begin
        rState    <= S_IDLE;
        rClkCnt   <= 16'd0;
        rBitIdx   <= 3'd0;
        rShiftReg <= 8'd0;
        oTxBusy   <= 1'b0;
        oTx       <= 1'b1;
    end
    else begin
        case (rState)
            S_IDLE: begin
                oTx       <= 1'b1;
                oTxBusy   <= 1'b0;
                rClkCnt   <= 16'd0;
                rBitIdx   <= 3'd0;

                if (iTxStart) begin
                    rShiftReg <= iTxData;
                    oTxBusy   <= 1'b1;
                    oTx       <= 1'b0;
                    rState    <= S_START;
                end
            end

            S_START: begin
                oTx <= 1'b0;

                if (rClkCnt < CLKS_PER_BIT - 1) begin
                    rClkCnt <= rClkCnt + 16'd1;
                end
                else begin
                    rClkCnt <= 16'd0;
                    rState  <= S_DATA;
                end
            end

            S_DATA: begin
                oTx <= rShiftReg[rBitIdx];

                if (rClkCnt < CLKS_PER_BIT - 1) begin
                    rClkCnt <= rClkCnt + 16'd1;
                end
                else begin
                    rClkCnt <= 16'd0;

                    if (rBitIdx < 3'd7)
                        rBitIdx <= rBitIdx + 3'd1;
                    else begin
                        rBitIdx <= 3'd0;
                        rState  <= S_STOP;
                    end
                end
            end

            S_STOP: begin
                oTx <= 1'b1;

                if (rClkCnt < CLKS_PER_BIT - 1) begin
                    rClkCnt <= rClkCnt + 16'd1;
                end
                else begin
                    rClkCnt <= 16'd0;
                    rState  <= S_IDLE;
                end
            end

            default: begin
                rState  <= S_IDLE;
                oTx     <= 1'b1;
                oTxBusy <= 1'b0;
            end
        endcase
    end
end

endmodule