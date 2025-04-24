`timescale 1ns / 1ps

module fpu(
        input  wire         rst,    // 高电平复位
        input  wire         clk,
        input  wire         start,  // start为1时，使用op、A、B开始计算
        input  wire         op,     // 为0时加, 为1时减
        input  wire [31:0]  A,      // 左操作数
        input  wire [31:0]  B,      // 右操作数
        output reg          ready,  // 复位或计算完成时ready为1，检测到start为1时置为0
        output wire [31:0]  C       // 计算结果
    );

    // TODO: 定义状态
    localparam IDLE    = 3'b000;
    localparam STORAGE = 3'b001;
    localparam EXPALIGN = 3'b010;
    localparam MANTSWAP = 3'b011;
    localparam MANTCALC = 3'b100;
    localparam MANTALIGN = 3'b101;
    localparam OUTPUT = 3'b110;
    localparam STOP = 3'b111;

    // 状态变量
    reg [2:0] next_state, cur_state;

    // TODO: 定义其他中间变量

    reg signA, signB, calmode, swapsign;
    reg [7:0] expA, expB, expC;
    reg [24:0] mantA, mantB, mantC;

    wire expc = expA > expB ? expA : expB;
    wire [7:0] d_exp = expA > expB ? expA - expB : expB - expA;

    reg [31:0] S_C;
    assign C = S_C;

    // 三段式第1段
    always @(posedge clk or posedge rst)
    begin
        cur_state <= rst ? IDLE : next_state;
    end

    // 三段式第2段
    always @(*)
    begin
        case (cur_state)
            IDLE:
                if (start)
                    next_state = STORAGE;
                else
                    next_state = IDLE;
            STORAGE:
                next_state = EXPALIGN;
            EXPALIGN:
                next_state = MANTSWAP;
            MANTSWAP:
                next_state = MANTCALC;
            MANTCALC:
                next_state = MANTALIGN;
            MANTALIGN:
                if (mantC[24] == 1)
                    next_state = OUTPUT;
                else
                    next_state = MANTALIGN;
            OUTPUT:
                next_state = STOP;
            STOP:
                next_state = IDLE;
            default:
                next_state = IDLE;
        endcase
    end

    // 三段式第3段
    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            ready <= 1;
        end
        else
        begin
            case (cur_state)
                IDLE:
                begin
                    if (start)
                        ready <= 0;
                    else
                        ready <= 1;
                end
                STORAGE:
                begin
                    ready <= 0;
                    signA <= A[31];
                    signB <= B[31];
                    expA <= A[30:23];
                    expB <= B[30:23];
                    mantA <= {2'b01, A[22:0]};
                    mantB <= {2'b01, B[22:0]};
                    calmode <= op;
                    swapsign <= 0;
                end
                EXPALIGN:
                begin
                    if (expA > expB)
                    begin
                        expC <= expA;
                        mantB <= mantB >> d_exp;
                    end
                    else
                    begin
                        mantA <= mantA >> d_exp;
                        expC <= expB;
                    end
                end
                MANTSWAP:
                begin
                    if (mantA < mantB)
                    begin
                        mantA <= mantB;
                        mantB <= mantA;
                        signA <= signB;
                        signB <= signA;
                        swapsign <= 1;
                    end
                end
                MANTCALC: // 4
                begin
                    S_C[31] <= signA ^ (swapsign & calmode);
                    case (signA ^ signB)
                        0:
                        case (calmode)
                            0:
                                mantC <= mantA + mantB;
                            1:
                                mantC <= mantA - mantB;
                        endcase
                        1:
                        case (calmode)
                            0:
                                mantC <= mantA - mantB;
                            1:
                                mantC <= mantA + mantB;
                        endcase
                    endcase
                end
                MANTALIGN:
                begin
                    expC <= expC - 1;
                    mantC <= mantC << 1;
                end
                OUTPUT:
                begin
                    S_C[22:0] <= mantC[24:2];
                    S_C[30:23] <= expC + 2;
                end
                STOP:
                begin
                    ready <= 1;
                end
                default:
                begin
                    ready <= 1;
                end
            endcase
        end
    end

endmodule
