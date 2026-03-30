`timescale 1ns/10ps

module PixelWindow_Gray #(
    parameter WIDTH  = 3840,
    parameter HEIGHT = 2880
)(
    input            iClk,
    input            iRsn,
    input            iPixelValid,
    input  [7:0]     iPixel,

    output reg       oPixelValid,
    output reg       oFrameDone,

    output reg [7:0] oPix00, oPix01, oPix02,
    output reg [7:0] oPix10, oPix11, oPix12,
    output reg [7:0] oPix20, oPix21, oPix22
);

 reg [7:0] line0 [0:WIDTH-1];
 reg [7:0] line1 [0:WIDTH-1];
 reg [7:0] line2 [0:WIDTH-1];

// 3840, 2880 대응
reg [11:0] x;
reg [11:0] y;

// window registers
reg [7:0] t0, t1, t2;
reg [7:0] m0, m1, m2;
reg [7:0] b0, b1, b2;

// bank select
wire [1:0] cur_bank = y % 3;
wire [1:0] mid_bank = (y >= 1) ? ((y - 1) % 3) : 0;
wire [1:0] top_bank = (y >= 2) ? ((y - 2) % 3) : 0;

// line read
function [7:0] read_line;
    input [1:0]  sel;
    input [11:0] col;
    begin
        case (sel)
            2'd0:    read_line = line0[col];
            2'd1:    read_line = line1[col];
            default: read_line = line2[col];
        endcase
    end
endfunction

wire [7:0] rd_top = (y >= 2) ? read_line(top_bank, x) : 8'd0;
wire [7:0] rd_mid = (y >= 1) ? read_line(mid_bank, x) : 8'd0;

always @(posedge iClk) begin
    if (!iRsn) begin
        x <= 12'd0;
        y <= 12'd0;

        t0 <= 8'd0; t1 <= 8'd0; t2 <= 8'd0;
        m0 <= 8'd0; m1 <= 8'd0; m2 <= 8'd0;
        b0 <= 8'd0; b1 <= 8'd0; b2 <= 8'd0;

        oPixelValid <= 1'b0;
        oFrameDone  <= 1'b0;

        oPix00 <= 8'd0; oPix01 <= 8'd0; oPix02 <= 8'd0;
        oPix10 <= 8'd0; oPix11 <= 8'd0; oPix12 <= 8'd0;
        oPix20 <= 8'd0; oPix21 <= 8'd0; oPix22 <= 8'd0;
    end
    else begin
        oPixelValid <= 1'b0;
        oFrameDone  <= 1'b0;

        if (iPixelValid) begin
            case (cur_bank)
                2'd0:    line0[x] <= iPixel;
                2'd1:    line1[x] <= iPixel;
                default: line2[x] <= iPixel;
            endcase

            if (x == 12'd0) begin
                t0 <= 8'd0; t1 <= 8'd0; t2 <= rd_top;
                m0 <= 8'd0; m1 <= 8'd0; m2 <= rd_mid;
                b0 <= 8'd0; b1 <= 8'd0; b2 <= iPixel;
            end
            else begin
                t0 <= t1; t1 <= t2; t2 <= rd_top;
                m0 <= m1; m1 <= m2; m2 <= rd_mid;
                b0 <= b1; b1 <= b2; b2 <= iPixel;
            end

            if (y >= 12'd1 && x >= 12'd1) begin
                oPixelValid <= 1'b1;

                oPix00 <= (x == 12'd1) ? 8'd0 : t0;
                oPix01 <= t1;
                oPix02 <= t2;

                oPix10 <= (x == 12'd1) ? 8'd0 : m0;
                oPix11 <= m1;
                oPix12 <= m2;

                oPix20 <= (x == 12'd1) ? 8'd0 : b0;
                oPix21 <= b1;
                oPix22 <= b2;
            end

            if (x == WIDTH-1) begin
                x <= 12'd0;

                if (y == HEIGHT-1) begin
                    y <= 12'd0;
                    oFrameDone <= 1'b1;
                end
                else begin
                    y <= y + 12'd1;
                end
            end
            else begin
                x <= x + 12'd1;
            end
        end
    end
end

endmodule