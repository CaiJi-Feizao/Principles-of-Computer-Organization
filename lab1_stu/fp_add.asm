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

    # TODO



    print a0    # 把计算结果存储到a0寄存器，使用print宏定义打印计算结果

    # 结束程序
    ori   a7, zero, 10
    ecall
