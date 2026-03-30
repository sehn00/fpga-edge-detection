module RgbAssembler (
    input         iClk,
    input         iRsn,
    input         iRxDone,
    input  [7:0]  iRxData,

    output reg        oPixelValid,
    output reg [23:0] oRgbPixel
);

reg [1:0] rByteCnt;
reg [7:0] rR, rG, rB;

always @(posedge iClk) begin
    if (!iRsn) begin
        rByteCnt   <= 2'd0;
        rR         <= 8'd0;
        rG         <= 8'd0;
        rB         <= 8'd0;
        oPixelValid <= 1'b0;
        oRgbPixel   <= 24'd0;
    end else begin
        oPixelValid <= 1'b0;

        if (iRxDone) begin
            case (rByteCnt)
                2'd0: begin
                    rR       <= iRxData;
                    rByteCnt <= 2'd1;
                end

                2'd1: begin
                    rG       <= iRxData;
                    rByteCnt <= 2'd2;
                end

                2'd2: begin
                    rB         <= iRxData;
                    oRgbPixel  <= {rR, rG, iRxData};
                    oPixelValid <= 1'b1;
                    rByteCnt   <= 2'd0;
                end

                default: begin
                    rByteCnt <= 2'd0;
                end
            endcase
        end
    end
end

endmodule