`timescale 1ns / 1ps

`include "defines.vh"

// 主存地址有效位宽：15bit
// Cache容量：127B
// Cache块大小：256bit (8*32bit)
// Cache块个数：?

module ICache(
        input  wire         cpu_clk,
        input  wire         cpu_rst,        // high active
        // Interface to CPU
        input  wire         inst_rreq,      // 来自CPU的取指请求
        input  wire [31:0]  inst_addr,      // 来自CPU的取指地址
        output reg          inst_valid,     // 输出给CPU的指令有效信号（读指令命中）
        output reg  [31:0]  inst_out,       // 输出给CPU的指令
        // Interface to Read Bus
        input  wire         dev_rrdy,       // 主存就绪信号（高电平表示主存可接收ICache的读请求）
        output reg  [ 3:0]  cpu_ren,        // 输出给主存的读使能信号
        output reg  [31:0]  cpu_raddr,      // 输出给主存的读地址
        input  wire         dev_rvalid,     // 来自主存的数据有效信号
        input  wire [255:0] dev_rdata       // 来自主存的读数据
    );

`ifdef ENABLE_ICACHE    /******** 不要修改此行代码 ********/

    // ICache存储体
    reg [3:0] valid;          // 有效位
    reg [9:0] tag  [3:0];     // 块标签
    reg [255:0] data [3:0];     // 数据块

    // TODO: 定义ICache状态机的状态及状态变量
    localparam IDLE = 2'b00;
    localparam TAG_CHK = 2'b01;
    localparam REFILL = 2'b10;

    reg [1:0] cur_state, next_state;

    // 主存地址分解
    wire [9:0] tag_from_cpu = inst_addr[14:5];
    wire [4:0] offset = inst_addr[4:0];

    reg [3:0] hit_arr;
    reg [1:0] hit_ad;

    // 记录各块被击中情况
    integer i;
    always @(*)
    begin
        hit_arr = 0;
        for (i = 0; i < 4; i = i + 1)
        begin
            if (tag_from_cpu == tag[i] & valid[i])
            begin
                hit_ad = i;
                hit_arr[i] = 1;
            end
        end
    end

    reg  [31:0] cnt;
    always @(posedge cpu_clk or posedge cpu_rst)
    begin
        if (cpu_rst)
            cnt <= 0;
        else if (inst_rreq)
            cnt <= cnt + 1;
        else if (inst_valid && cnt > 0)
            cnt <= cnt - 1;
    end

    wire hit = |hit_arr;

    always @(*)
    begin
        inst_valid = hit && (cnt > 0);
        inst_out   = ~hit ? 32'h00000000 : data[hit_ad][offset * 8 +: 32];
    end

    // TODO: 编写状态机现态的更新逻辑
    always @(posedge cpu_clk or posedge cpu_rst)
    begin
        cur_state <= cpu_rst ? IDLE : next_state;
    end

    // TODO: 编写状态机的状态转移逻辑
    always @(*)
    begin
        case (cur_state)
            IDLE:
                next_state = inst_rreq ? TAG_CHK : IDLE;
            TAG_CHK:
                next_state = hit ? IDLE : REFILL;
            REFILL:
                next_state = dev_rvalid ? TAG_CHK : REFILL;
            default:
                next_state = IDLE;
        endcase
    end

    always @(*)
    begin
        cpu_raddr = inst_addr;
    end

    // TODO: 生成状态机的输出信号
    always @(posedge cpu_clk or posedge cpu_rst)
    begin
        if (cpu_rst)
        begin
            cpu_ren <= 4'h0;
        end
        case (cur_state)
            IDLE:
            begin
                cpu_ren <= 4'h0;
            end
            TAG_CHK:
                if (~hit)
                    cpu_ren <= 4'hf;
            REFILL:
            begin
                cpu_ren <= 4'h0;
            end
            default:
            begin
                cpu_ren <= 4'h0;
            end
        endcase
    end

    // TODO: 编写更新Cache有效位、块标签、数据块的逻辑

    reg [1:0] free_index;
    wire [1:0] replace_index = (&valid) ? lfsr[1:0] : free_index;
    always @(posedge cpu_clk or posedge cpu_rst)
    begin
        if (cpu_rst)
            free_index <= 0;
        else
        begin
            if (dev_rvalid && ~(&valid))
                free_index <= free_index + 1;
        end
    end

    always @(posedge cpu_clk or posedge cpu_rst)
    begin
        if (cpu_rst)
            valid <= 0;
        else if(dev_rvalid)
            valid[replace_index] = 1;
    end

    reg [3:0] lfsr;
    always @(posedge cpu_clk or posedge cpu_rst)
    begin
        lfsr <= cpu_rst ? 4'h1 : {lfsr[2:0], lfsr[2] ^ lfsr[3]};
    end

    always @(*)
    begin
        if (dev_rvalid && cur_state == REFILL)
        begin
            tag[replace_index] = tag_from_cpu;
            data[replace_index] = dev_rdata;
        end
    end

    /******** 不要修改以下代码 ********/
`else

    localparam IDLE  = 2'b00;
    localparam STAT0 = 2'b01;
    localparam STAT1 = 2'b11;
    reg [1:0] state, nstat;

    always @(posedge cpu_clk or posedge cpu_rst)
    begin
        state <= cpu_rst ? IDLE : nstat;
    end

    always @(*)
    begin
        case (state)
            IDLE:
                nstat = inst_rreq ? (dev_rrdy ? STAT1 : STAT0) : IDLE;
            STAT0:
                nstat = dev_rrdy ? STAT1 : STAT0;
            STAT1:
                nstat = dev_rvalid ? IDLE : STAT1;
            default:
                nstat = IDLE;
        endcase
    end

    always @(posedge cpu_clk or posedge cpu_rst)
    begin
        if (cpu_rst)
        begin
            inst_valid <= 1'b0;
            cpu_ren    <= 4'h0;
        end
        else
        begin
            case (state)
                IDLE:
                begin
                    inst_valid <= 1'b0;
                    cpu_ren    <= (inst_rreq & dev_rrdy) ? 4'hF : 4'h0;
                    cpu_raddr  <= inst_rreq ? inst_addr : 32'h0;
                end
                STAT0:
                begin
                    cpu_ren    <= dev_rrdy ? 4'hF : 4'h0;
                end
                STAT1:
                begin
                    cpu_ren    <= 4'h0;
                    inst_valid <= dev_rvalid ? 1'b1 : 1'b0;
                    inst_out   <= dev_rvalid ? dev_rdata[31:0] : 32'h0;
                end
                default:
                begin
                    inst_valid <= 1'b0;
                    cpu_ren    <= 4'h0;
                end
            endcase
        end
    end

`endif

endmodule
