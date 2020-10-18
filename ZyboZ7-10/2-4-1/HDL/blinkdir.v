module blinkdir (
    input               CLK,
    input               RST,
    input       [0:0]   BTN,
    output  reg [3:0]   LED
);

// チャタリング除去回路を接続
wire CHGMODE;

debounce debounce (.CLK(CLK), .RST(RST), .BTNIN(BTN[0]), .BTNOUT(CHGMODE));

// System Clockを分周
reg [24:0] cnt25;

always @( posedge CLK ) begin
    if ( RST || CHGMODE )
        cnt25 <= 25'h0;
    else
        cnt25 <= cnt25 + 25'h1;
end

// LED用カウンタのEnableを作成
wire ledcnten = &cnt25[22:0];

// LED direction state (0:<->, 1:->, 2:<-)
reg [1:0] dir;
localparam BOTH = 0, L2R = 1, R2L = 2;
localparam DIRLIMIT = R2L;

always @( posedge CLK ) begin
    if ( RST )
        dir <= 2'd0;
    else if ( CHGMODE )
        if ( dir == DIRLIMIT )
            dir <= 2'd0;
        else
            dir <= dir + 2'd1;
end

// LED用カウンタ
reg [2:0] cnt3;

always @( posedge CLK ) begin
    if ( RST )
        cnt3 <= 3'd0;
    else if ( ledcnten )
        if ( dir == BOTH && cnt3 == 3'd5 )
            cnt3 <=3'd0;
        else if ( dir != BOTH && cnt3 == 3'd3 )
            cnt3 <=3'd0;
        else
            cnt3 <= cnt3 + 1'd1;
end

always @* begin
    case ( dir )
        // dir: <->
        2'd0: begin
            case ( cnt3 )
                3'd0:   LED = 4'b0001;
                3'd1:   LED = 4'b0010;
                3'd2:   LED = 4'b0100;
                3'd3:   LED = 4'b1000;
                3'd4:   LED = 4'b0100;
                3'd5:   LED = 4'b0010;
                default:LED = 4'b0000;
            endcase            
        end
        // dir: ->
        2'd1: begin
            case ( cnt3[1:0] )
                3'd0:   LED = 4'b1000;
                3'd1:   LED = 4'b0100;
                3'd2:   LED = 4'b0010;
                3'd3:   LED = 4'b0001;
                default:LED = 4'b0000;
            endcase
        end
        // dir: <-
        2'd2: begin
            case ( cnt3[1:0] )
                3'd0:   LED = 4'b0001;
                3'd1:   LED = 4'b0010;
                3'd2:   LED = 4'b0100;
                3'd3:   LED = 4'b1000;
                default:LED = 4'b0000;
            endcase            
        end
        default:LED = 4'b0000;
    endcase
end

endmodule
