.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ mode3 framebuffer: pixel0=green(0x03E0), pixel1=red(0x001F), pixel2=blue(0x7C00), pixel3=white
    ldr r6, =0x06000000
    ldr r1, =0x03E0
    strh r1, [r6]
    ldr r1, =0x001F
    strh r1, [r6, #2]
    ldr r1, =0x7C00
    strh r1, [r6, #4]
    ldr r1, =0x7FFF
    strh r1, [r6, #6]
    @ enable green swap (reg 0x2 bit0)
    mov r1, #1
    strh r1, [r0, #2]
    @ DISPCNT mode3 BG2
    ldr r1, =0x0403
    strh r1, [r0]
forever:
    b forever
