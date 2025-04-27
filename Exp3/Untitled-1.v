`timescale 1ns / 1ps

`include "defines.vh"

// 锟斤拷锟斤拷锟街凤拷锟叫伙拷锟斤拷锟�?15bit
// Cache锟斤拷锟斤拷锟斤拷127B
// Cache锟斤拷锟叫★拷锟�?256bit (8*32bit)
// Cache锟斤拷锟斤拷锟斤拷锟�??//4

module ICache(
        input  wire         cpu_clk,
        input  wire         cpu_rst,        // high active
        // Interface to CPU
        input  wire         inst_rreq,      // 锟斤拷锟斤拷CPU锟斤拷取指锟斤拷锟斤拷
        input  wire [31:0]  inst_addr,      // 锟斤拷锟斤拷CPU锟斤拷取指锟斤拷址
        output reg          inst_valid,     // 锟斤拷锟斤拷锟紺PU锟斤拷指锟斤拷锟斤拷效锟脚号ｏ拷锟斤拷指锟斤拷锟斤拷锟叫ｏ拷
        output reg  [31:0]  inst_out,       // 锟斤拷锟斤拷锟紺PU锟斤拷指锟斤拷
        // Interface to Read Bus
        input  wire         dev_rrdy,       // 锟斤拷锟斤拷锟斤拷锟斤拷藕牛锟斤拷叩锟狡斤拷锟绞撅拷锟斤拷锟缴斤拷锟斤拷ICache锟侥讹拷锟斤拷锟斤拷
        output reg  [ 3:0]  cpu_ren,        // 锟斤拷锟斤拷锟斤拷锟斤拷锟侥讹拷使锟斤拷锟脚猴拷
        output reg  [31:0]  cpu_raddr,      // 锟斤拷锟斤拷锟斤拷锟斤拷锟侥讹拷锟斤拷址
        input  wire         dev_rvalid,     // 锟斤拷锟斤拷锟斤拷锟斤拷锟斤拷锟斤拷锟斤拷锟叫э拷藕锟�?
        input  wire [255:0] dev_rdata       // 锟斤拷锟斤拷锟斤拷锟斤拷亩锟斤拷锟斤拷锟�?
    );

`ifdef ENABLE_ICACHE    /******** 锟斤拷要锟睫改达拷锟叫达拷锟斤拷 ********/

    reg judge_hit;
    reg [1:0] rand_lfsr;
    reg [3:0] locate;
    reg [14:0] local_tag;
    reg [2:0] local_offset;
    reg [31:0] local_addr;
    reg [255:0] local_data;
    // ICache锟芥储锟斤拷
    reg [3:0] valid;          // 锟斤拷效位
    reg [9:0] tag  [3:0];     // 锟斤拷锟斤拷?
    reg [255:0] data [3:0];     // 锟斤拷锟捷匡拷

    // TODO: 锟斤拷锟斤拷ICache状态锟斤拷锟斤拷状态锟斤拷状态锟斤拷锟斤拷
    localparam IDLE  = 2'b00;
    localparam CHECK = 2'b01;
    localparam REFILL = 2'b10;
    reg cur_state[1:0];
    reg next_state[1:0];

    // 锟斤拷锟斤拷锟街凤拷纸锟�?
    wire [9:0] tag_from_cpu = inst_addr[14:5];
    wire [4:0] offset       = inst_addr[4:0];

    //  wire hit = /* TODO */;
    always @(posedge cpu_clk or posedge cpu_rst)
    begin
        if(cpu_rst==1'b1)
        begin
            rand_lfsr<=2'b11;
        end
        else
        begin
            rand_lfsr[0]<=rand_lfsr[0]^rand_lfsr[1];
            rand_lfsr[1]<=rand_lfsr[0];
        end
    end


    always @(*)
    begin
        inst_valid = judge_hit;
        if(local_offset==3'b000)
        begin
            inst_out=data[locate][31:0];
        end
        else if(local_offset==3'b001)
        begin
            inst_out=data[locate][31+1*32:1*32];
        end
        else if(local_offset==3'b010)
        begin
            inst_out=data[locate][31+2*32:2*32];   
        end
        else if(local_offset==3'b011)
        begin
            inst_out=data[locate][31+3*32:3*32];
        end
        else if(local_offset==3'b100)
        begin
            inst_out=data[locate][31+4*32:4*32];
        end
        else if(local_offset==3'b101)
        begin
            inst_out=data[locate][31+5*32:5*32];
        end
        else if(local_offset==3'b110)
        begin
            inst_out=data[locate][31+6*32:6*32];
        end
        else if(local_offset==3'b111)
        begin
            inst_out=data[locate][31+7*32:7*32];
        end
        else
        begin
            inst_out=32'b0;
        end
    end

    // TODO: 锟斤拷写状态锟斤拷锟斤拷态锟侥革拷锟斤拷锟竭硷拷
    always @(posedge cpu_clk or posedge cpu_rst)
    begin
        if (cpu_rst==1'b1)
            cur_state <= IDLE;
        else
            cur_state <= next_state;
    end

    // TODO: 锟斤拷写状态锟斤拷锟斤拷状态转锟斤拷锟竭硷拷
    always @(*)
    begin
        case(cur_state)
            IDLE:
            begin
                if(inst_rreq==1'b1)
                begin
                    next_state=CHECK;
                end
                else
                begin
                    next_state=IDLE; 
                end
            end
            CHECK:
            begin
                if(locate>=3'b100)
                begin
                    next_state=REFILL;
                end
                else
                begin
                    if(judge_hit==1'b1)
                    begin
                        next_state=IDLE;
                    end
                    else
                    begin
                        next_state=CHECK;
                    end
                end
            end
            REFILL:
            begin
            end
            default:
            begin
            end
        endcase
    end


    // TODO: 锟斤拷锟斤拷状态锟斤拷锟斤拷锟斤拷锟斤拷藕锟�?
    always @(posedge cpu_clk or posedge cpu_rst)
    begin
        if(cpu_rst==1'b1)
        begin
            cpu_ren<=4'b0;
            cpu_raddr<=32'b0;
            inst_valid<=1'b0;
            inst_out<=32'b0;
        end
        else
        begin
            case(cur_state)
                IDLE:
                begin
                    cpu_ren<=4'b0000;
                    cpu_raddr<=32'b0;
                end
                CHECK:
                begin
                    if(locate>=3'b100)
                    begin
                        cpu_ren<=4'b1111;
                        cpu_raddr<=local_addr;
                    end
                    else
                    begin
                        cpu_ren<=4'b0000;
                        cpu_raddr<=32'b0;
                    end
                end
                REFILL:
                begin
                    cpu_ren<=4'b0000;
                    cpu_raddr<=32'b0;
                end
                default:
                begin
                    cpu_ren<=4'b0000;
                    cpu_raddr<=32'b0;
                end
            endcase
        end
    end

    // TODO: 锟斤拷写锟斤拷锟斤拷Cache锟斤拷效位锟斤拷锟斤拷锟角╋拷锟斤拷锟斤拷菘锟斤拷锟竭硷拷
    always @(posedge cpu_clk or posedge cpu_rst)
    begin
        if(cpu_rst==1'b1)
            ;
        else
        begin
            if(inst_rreq==1'b1)
            begin
                local_tag<=tag_from_cpu;
                local_offset<=offset;
                local_addr<=inst_addr;
            end
            else
            begin
                local_tag<=local_tag;
                loacl_offset<=local_offset; 
                local_addr<=local_addr;
            end
        end
    end

    always @(posedge cpu_clk or posedge cpu_rst)
    begin
        if(cpu_rst==1'b1)
        begin
            judge_hit<=1'b0;
            locate<=3'b0;
        end
        else
        begin
            if(cur_state==CHECK)
            begin
                if(locate>=3'b100)
                begin
                    judge_hit<=1'b0;
                    locate<=3'b100;
                end
                else
                begin
                    if(local_tag==tag[locate])
                    begin
                        judge_hit<=1'b1;
                        locate<=locate;
                    end
                    else
                    begin
                        judge_hit<=1'b0;
                        locate<=locate+3'b1;
                    end
                end
            end
            else if(cur_state==REFILL)
            begin
                if(dev_rvalid==1'b1)
                begin
                    judge_hit<=1'b0;
                    locate<=rand_lfsr;
                end
                else
                begin
                    if(locate>=3'b100)
                    begin
                        judge_hit<=1'b0;
                        locate<=3'b100;
                    end
                    else
                    begin
                        judge_hit<=1'b1;
                        locate<=locate;
                    end
                end
            end
            else
            begin
                judge_hit<=1'b0;
                locate<=3'b0;
            end
        end
    end


    always @(posedge cpu_clk or posedge cpu_rst)
    begin
        if(cpu_rst==1'b1)
        begin
            local_data<=256'b0;
        end
        else
        begin
            if(dev_rvalid==1'b1)
            begin
                local_data<=dev_rdata;
            end
            else
            begin
                local_data<=local_data;
            end
        end
    end

    

            /******** 锟斤拷要锟睫革拷锟斤拷锟铰达拷锟斤拷 ********//*Dont_Move*/
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
