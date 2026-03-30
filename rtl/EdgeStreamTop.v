`timescale 1ns/1ps

module EdgeStreamTop #(
    parameter WIDTH    = 3840,
    parameter HEIGHT   = 2880,
    parameter CLK_FREQ = 75_000_000,
    parameter BAUD     = 2000000
)(
    input  wire iClk,      // FPGA input clock (ex. 100MHz)
    input  wire iRsn,      // active-high reset release
    input  wire iUartRx,   // UART RX from PC
    output wire oUartTx    // UART TX to PC
);

////////////////////////////////////////////////////////////
// 90MHz clock generation
////////////////////////////////////////////////////////////

wire wClk90;
wire wClkLocked;
wire wRsn;

assign wRsn = iRsn & wClkLocked;

// Vivado에서 생성된 Clocking Wizard 이름/포트명에 맞게 수정
clk_wiz_pixel u_clk_wiz_pixel (
    .clk_in1 (iClk),
    .reset   (~iRsn),
    .clk_out1(wClk90),
    .locked  (wClkLocked)
);

////////////////////////////////////////////////////////////
// UART RX
////////////////////////////////////////////////////////////

wire [7:0] wRxData;
wire       wRxDone;

UartRx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD    (BAUD)
) u_UartRx (
    .iClk   (wClk90),
    .iRsn   (wRsn),
    .iRx    (iUartRx),
    .oRxData(wRxData),
    .oRxDone(wRxDone)
);

////////////////////////////////////////////////////////////
// RGB Assembler : 3 bytes -> 1 RGB888 pixel
////////////////////////////////////////////////////////////

wire        wRgbValid;
wire [23:0] wRgbPixel;

RgbAssembler u_RgbAssembler (
    .iClk       (wClk90),
    .iRsn       (wRsn),
    .iRxDone    (wRxDone),
    .iRxData    (wRxData),
    .oPixelValid(wRgbValid),
    .oRgbPixel  (wRgbPixel)
);

////////////////////////////////////////////////////////////
// RGB -> Gray
////////////////////////////////////////////////////////////

wire [7:0] wGrayPixel;

Rgb2Gray u_Rgb2Gray (
    .iRgb (wRgbPixel),
    .oGray(wGrayPixel)
);

////////////////////////////////////////////////////////////
// Pixel Window (Gray 8-bit stream)
////////////////////////////////////////////////////////////

wire       wWinValid;
wire       wFrameDone;
wire [7:0] wPix00, wPix01, wPix02;
wire [7:0] wPix10, wPix11, wPix12;
wire [7:0] wPix20, wPix21, wPix22;

PixelWindow_Gray #(
    .WIDTH (WIDTH),
    .HEIGHT(HEIGHT)
) u_PixelWindow_Gray (
    .iClk       (wClk90),
    .iRsn       (wRsn),
    .iPixelValid(wRgbValid),
    .iPixel     (wGrayPixel),

    .oPixelValid(wWinValid),
    .oFrameDone (wFrameDone),

    .oPix00     (wPix00),
    .oPix01     (wPix01),
    .oPix02     (wPix02),

    .oPix10     (wPix10),
    .oPix11     (wPix11),
    .oPix12     (wPix12),

    .oPix20     (wPix20),
    .oPix21     (wPix21),
    .oPix22     (wPix22)
);

////////////////////////////////////////////////////////////
// Sobel
////////////////////////////////////////////////////////////

wire [7:0] wEdgePixel;

SobelGray #(
    .THRESHOLD(8'd185)
) u_SobelGray (
    .iPix00(wPix00),
    .iPix01(wPix01),
    .iPix02(wPix02),

    .iPix10(wPix10),
    .iPix11(wPix11),
    .iPix12(wPix12),

    .iPix20(wPix20),
    .iPix21(wPix21),
    .iPix22(wPix22),

    .oEdge (wEdgePixel)
);

////////////////////////////////////////////////////////////
// Output register / skid buffer
////////////////////////////////////////////////////////////

wire wFifoFull;
wire wFifoEmpty;
wire [7:0] wFifoDataOut;

reg  [7:0] rEdgeData;
reg        rEdgeValid;

wire wFifoWrEn;
assign wFifoWrEn = rEdgeValid & ~wFifoFull;

always @(posedge wClk90) begin
    if (!wRsn) begin
        rEdgeData  <= 8'd0;
        rEdgeValid <= 1'b0;
    end
    else begin
        if (wFifoWrEn) begin
            rEdgeValid <= 1'b0;
        end
        else if (rEdgeValid && wFifoFull) begin
            rEdgeData  <= rEdgeData;
            rEdgeValid <= rEdgeValid;
        end
        else begin
            rEdgeValid <= wWinValid;

            if (wWinValid)
                rEdgeData <= wEdgePixel;
        end
    end
end

////////////////////////////////////////////////////////////
// FIFO (single clock)
////////////////////////////////////////////////////////////

reg rFifoRd;

PixelFIFO u_PixelFIFO (
    .iClk   (wClk90),
    .iRsn   (wRsn),

    .iWrEn  (wFifoWrEn),
    .iWrData(rEdgeData),
    .oFull  (wFifoFull),

    .iRdEn  (rFifoRd),
    .oRdData(wFifoDataOut),
    .oEmpty (wFifoEmpty)
);

////////////////////////////////////////////////////////////
// UART TX
////////////////////////////////////////////////////////////

reg  [7:0] rTxData;
reg        rTxStart;
wire       wTxBusy;

UartTx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD    (BAUD)
) u_UartTx (
    .iClk    (wClk90),
    .iRsn    (wRsn),
    .iTxStart(rTxStart),
    .iTxData (rTxData),
    .oTxBusy (wTxBusy),
    .oTx     (oUartTx)
);

////////////////////////////////////////////////////////////
// FIFO -> UART TX FSM
////////////////////////////////////////////////////////////

localparam S_IDLE = 2'd0;
localparam S_WAIT = 2'd1;
localparam S_SEND = 2'd2;

reg [1:0] rTxState;

always @(posedge wClk90) begin
    if (!wRsn) begin
        rTxState <= S_IDLE;
        rFifoRd  <= 1'b0;
        rTxStart <= 1'b0;
        rTxData  <= 8'd0;
    end
    else begin
        rFifoRd  <= 1'b0;
        rTxStart <= 1'b0;

        case (rTxState)
            S_IDLE: begin
                if (!wTxBusy && !wFifoEmpty) begin
                    rFifoRd  <= 1'b1;
                    rTxState <= S_WAIT;
                end
            end

            S_WAIT: begin
                rTxData  <= wFifoDataOut;
                rTxStart <= 1'b1;
                rTxState <= S_SEND;
            end

            S_SEND: begin
                if (wTxBusy)
                    rTxState <= S_IDLE;
            end

            default: rTxState <= S_IDLE;
        endcase
    end
end

endmodule