.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0
    strh r1, [r12]
    ldr r6, =0x06000000
    mov r0, #7                 @ DivArm: r0=denom, r1=numer
    mov r1, #100
    swi 0x070000
    strh r0, [r6]              @ quotient (100/7=14)
    strh r1, [r6, #2]          @ remainder (100%7=2)
    ldr r0, =0x4000            @ ArcTan: r0 = 1.0 in .14 -> arctan(1)=45deg
    swi 0x090000
    strh r0, [r6, #4]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
