`timescale 1ns/1ps

module UartRx #(
    parameter CLK_FREQ = 75_000_000,
    parameter BAUD     = 2000000
)(
    input  wire       iClk,
    input  wire       iRsn,
    input  wire       iRx,
    output reg [7:0]  oRxData,
    output reg        oRxDone
);

localparam integer CLKS_PER_BIT  = CLK_FREQ / BAUD;
localparam integer HALF_BIT_CLKS = CLKS_PER_BIT / 2;

localparam [1:0] S_IDLE  = 2'd0;
localparam [1:0] S_START = 2'd1;
localparam [1:0] S_DATA  = 2'd2;
localparam [1:0] S_STOP  = 2'd3;

reg [1:0]  rState;
reg [15:0] rClkCnt;
reg [2:0]  rBitIdx;
reg [7:0]  rShift;

reg rRxMeta, rRxSync, rRxPrev;

wire wStartEdge = (rRxPrev == 1'b1) && (rRxSync == 1'b0);

always @(posedge iClk) begin
    if (!iRsn) begin
        rRxMeta <= 1'b1;
        rRxSync <= 1'b1;
        rRxPrev <= 1'b1;
    end else begin
        rRxMeta <= iRx;
        rRxSync <= rRxMeta;
        rRxPrev <= rRxSync;
    end
end

always @(posedge iClk) begin
    if (!iRsn) begin
        rState  <= S_IDLE;
        rClkCnt <= 16'd0;
        rBitIdx <= 3'd0;
        rShift  <= 8'd0;
        oRxData <= 8'd0;
        oRxDone <= 1'b0;
    end else begin
        oRxDone <= 1'b0;

        case (rState)
            S_IDLE: begin
                rClkCnt <= 16'd0;
                rBitIdx <= 3'd0;

                if (wStartEdge)
                    rState <= S_START;
            end

            S_START: begin
                if (rClkCnt == HALF_BIT_CLKS-1) begin
                    rClkCnt <= 16'd0;

                    if (rRxSync == 1'b0)
                        rState <= S_DATA;
                    else
                        rState <= S_IDLE;
                end else begin
                    rClkCnt <= rClkCnt + 16'd1;
                end
            end

            S_DATA: begin
                if (rClkCnt == CLKS_PER_BIT-1) begin
                    rClkCnt <= 16'd0;
                    rShift[rBitIdx] <= rRxSync;

                    if (rBitIdx == 3'd7)
                        rState <= S_STOP;
                    else
                        rBitIdx <= rBitIdx + 3'd1;
                end else begin
                    rClkCnt <= rClkCnt + 16'd1;
                end
            end

            S_STOP: begin
                if (rClkCnt == CLKS_PER_BIT-1) begin
                    rClkCnt <= 16'd0;
                    rState  <= S_IDLE;
                    oRxData <= rShift;
                    oRxDone <= 1'b1;
                end else begin
                    rClkCnt <= rClkCnt + 16'd1;
                end
            end

            default: begin
                rState <= S_IDLE;
            end
        endcase
    end
end

endmodule