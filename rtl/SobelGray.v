module SobelGray #(
    parameter THRESHOLD = 8'd185
)(
    input  [7:0] iPix00,
    input  [7:0] iPix01,
    input  [7:0] iPix02,
    input  [7:0] iPix10,
    input  [7:0] iPix11,
    input  [7:0] iPix12,
    input  [7:0] iPix20,
    input  [7:0] iPix21,
    input  [7:0] iPix22,

    output [7:0] oEdge
);

wire signed [10:0] s00 = {3'b000, iPix00};
wire signed [10:0] s01 = {3'b000, iPix01};
wire signed [10:0] s02 = {3'b000, iPix02};
wire signed [10:0] s10 = {3'b000, iPix10};
wire signed [10:0] s12 = {3'b000, iPix12};
wire signed [10:0] s20 = {3'b000, iPix20};
wire signed [10:0] s21 = {3'b000, iPix21};
wire signed [10:0] s22 = {3'b000, iPix22};

wire signed [12:0] gx =
    -s00 + s02
    - (s10 <<< 1) + (s12 <<< 1)
    - s20 + s22;

wire signed [12:0] gy =
    -s00 - (s01 <<< 1) - s02
    + s20 + (s21 <<< 1) + s22;

wire [12:0] abs_gx = gx[12] ? -gx : gx;
wire [12:0] abs_gy = gy[12] ? -gy : gy;

wire [12:0] mag_raw = abs_gx + abs_gy;
wire [12:0] mag_div = mag_raw >> 1;   // 2로 나누기
wire [7:0] edge_pixel = (mag_div > 13'd255) ? 8'd255 : mag_div[7:0];

assign oEdge = (edge_pixel >= THRESHOLD) ? 8'hFF : 8'h00;

endmodule