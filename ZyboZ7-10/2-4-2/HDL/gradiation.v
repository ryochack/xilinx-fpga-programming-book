module gradiation (
    input               CLK,
    input               RST,
    output  reg [3:0]   VGA_R,
    output  reg [3:0]   VGA_G,
    output  reg [3:0]   VGA_B,
    output              VGA_HS,
    output              VGA_VS
);

// VGA用パラメータ読み込み
`include "vga_param.vh"

// 640x480の描画範囲を10x4のブロックに区切る
localparam HSIZE = 10'd64;  // 640 / 10 = 64
localparam VSIZE = 10'd120; // 480 / 4 = 120

// 同期信号作成回路の接続
wire        PCK;
wire [9:0]  HCNT, VCNT;

syncgen syncgen(
    .CLK    (CLK),
    .RST    (RST),
    .PCK    (PCK),
    .VGA_HS (VGA_HS),
    .VGA_VS (VGA_VS),
    .HCNT   (HCNT),
    .VCNT   (VCNT)
);

// RGB出力を作成
wire [9:0]  HBLANK = HFRONT + HWIDTH + HBACK;
wire [9:0]  VBLANK = VFRONT + VWIDTH + VBACK;
wire [9:0]  HIDX = HCNT - HBLANK + 10'd1;
wire [9:0]  VIDX = VCNT - VBLANK;
wire [3:0]  HNO = (HIDX - ((HIDX / HSIZE) * HSIZE)) / 4;
wire [3:0]  VNO = VIDX / VSIZE;

wire disp_enable = (VBLANK <= VCNT)
                && (HBLANK - 10'd1 <= HCNT) && (HCNT < HPERIOD - 10'd1);

// 描画ブロックの並びは以下。
// | W | W | ... | W |
// | R | R | ... | R |
// | G | G | ... | G |
// | B | B | ... | B |
// 各ブロックは横方向に16階調のグラディエーションがされる（4ドット毎に1階調明るくなる）
wire [3:0]  r = (VNO == 4'h0 || VNO == 4'h1) ? HNO[3:0] : 4'h0;
wire [3:0]  g = (VNO == 4'h0 || VNO == 4'h2) ? HNO[3:0] : 4'h0;
wire [3:0]  b = (VNO == 4'h0 || VNO == 4'h3) ? HNO[3:0] : 4'h0;

always @( posedge PCK ) begin
    if ( RST || !disp_enable )
        {VGA_R, VGA_G, VGA_B} <= 12'h000;
    else
        {VGA_R, VGA_G, VGA_B} <= { r, g, b };
end

endmodule