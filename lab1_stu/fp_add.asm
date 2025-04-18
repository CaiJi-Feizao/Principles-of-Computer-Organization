.data
    float1: .float -9.777
    float2: .float -1.234

.macro push %a
    addi sp, sp, -4
    sw   %a, 0(sp)
.end_macro

.macro pop %a
    lw   %a, 0(sp)
    addi sp, sp, 4
.end_macro

.macro print %a             	# print a floating-point number
    fmv.s.x	fa0, %a
    ori		a7, zero, 2
    ecall
.end_macro

.text
MAIN:
	lui s0, 0x10010
	lw 	a2, 0(s0)
	lw 	a3, 4(s0)
    jal ra, MYADD
    print a0    # 把计算结果存储到a0寄存器，使用print宏定义打印计算结果

    # 结束程序
    ori   a7, zero, 10
    ecall

MYADD:
    push s2
    push s3
    push s4
    push s5
    push s6
    push s7
    push s8
	
	# Sign
	lui t1, 0x80000
    and s2, a2, t1
    and s3, a3, t1
    srli s2, s2, 31
    srli s3, s3, 31
	# exp
	lui t1, 0x7f800
    and s4, a2, t1
    and s5, a3, t1
    srli s4, s4, 23
    srli s5, s5, 23
	# mant
	lui t1, 0x00800
	addi t2, t1, 0xffffffff
    and s6, a2, t2
    and s7, a3, t2
    or s6, s6, t1
    or s7, s7, t1

    sub s8, s4, s5   # exp_delta
    srl s7, s7, s8

    add s8, s6, s7
	
	lui t1, 0xff000
    and s9, s8, t1
    
    beq s9, zero, NOTRIGHTALIGN # 若无需右规，就跳过右规指令，否则顺序执行
    srli s8, s8, 1
    addi s4, s4, 1
NOTRIGHTALIGN:

    and s8, s8, t2
    slli s2, s2, 31
    slli s4, s4, 23
    or a0, s2, s4
    or a0, a0, s8

    pop s8
    pop s7
    pop s6
    pop s5
    pop s4
    pop s3
    pop s2

    jalr zero, 0(ra)
    
