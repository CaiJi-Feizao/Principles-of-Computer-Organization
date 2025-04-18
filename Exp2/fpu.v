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
    localparam IDLE    = 4'b0000;
    localparam STORAGE = 4'b0001;
    localparam EXPALIGN = 4'b0010;
    localparam MANTSWAP = 4'b0011;
    localparam MANTCALC = 4'b0100;
    localparam MANTALIGN = 4'b0101;
    localparam OUTPUT = 4'b0110;
    localparam STOP = 4'b0111;
    localparam NOTNORMAL = 4'b1010;
    localparam NOTNORMAL_OUTPUT = 4'b1110;

    // 状态变量
    reg [3:0] next_state, cur_state;

    // TODO: 定义其他中间变量

    reg signA, signB, calmode, swapsign, normalsign;
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
                if (A[30:23] == 8'h00)
                    next_state = NOTNORMAL;
                else
                    next_state = EXPALIGN;
            EXPALIGN:
                next_state = MANTSWAP;
            MANTSWAP:
                next_state = MANTCALC;
            MANTCALC:
                if (A[30:23] == 8'h00)
                begin
                    if ()
                    end
            next_state = NOTNORMAL_OUTPUT;
            else
                next_state = MANTALIGN;
            MANTALIGN:
                if (mantC[24] == 1)
                    next_state = OUTPUT;
                else if (expC == 0)
                    next_state = NTNN;
                else
                    next_state = MANTALIGN;
            OUTPUT:
                next_state = STOP;
            STOP:
                next_state = IDLE;
            NOTNORMAL:
                next_state = MANTSWAP;
            NOTNORMAL_OUTPUT:
                next_state = STOP;
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
                NOTNORMAL:
                begin
                    mantA <= {2'b00, mantA[22:0]};
                    mantB <= {2'b00, mantB[22:0]};
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
                    if (calmode == 0)
                        S_C[31] <= signA;
                    else
                        S_C[31] <= signA ^ swapsign;
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
                NOTNORMAL_OUTPUT:
                begin
                    S_C[22:0] <= mantC[22:0];
                    S_C[30:23] <= 8'h0;
                end
                default:
                begin
                    normalsign <= 1;
                    ready <= 1;
                end
            endcase
        end
    end

endmodule

