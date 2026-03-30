module Rgb2Gray (
    input  [23:0] iRgb,
    output [7:0]  oGray
);

assign oGray =
    (iRgb[23:16] >> 2) +
    (iRgb[23:16] >> 5) +
    (iRgb[15:8]  >> 1) +
    (iRgb[15:8]  >> 4) +
    (iRgb[7:0]   >> 3);

endmodule