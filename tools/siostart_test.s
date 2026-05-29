.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r5, =0x04000128        @ SIOCNT
    ldr r1, =0x0081           @ internal clock (bit0) + start (bit7), normal mode
    strh r1, [r5]
    @ delay ~2000 cycles
    ldr r2, =1500
1:  subs r2, r2, #1
    bne 1b
    ldrh r3, [r5]             @ read SIOCNT after delay
    ldr r1, =0x7FFF
    and r3, r3, r1
    ldr r1, =0x05000000
    strh r3, [r1]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
