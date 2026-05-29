.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ fill rows 0-79 red (9600 words), rows 80-159 blue
    ldr r0, =0x06000000
    ldr r1, =0x001F001F
    ldr r3, =9600
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x7C007C00
    ldr r3, =9600
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    @ BG2 affine PA=256 PD=128 (2x vertical zoom), PB=PC=0, ref=0
    ldr r1, =0x0100
    strh r1, [r12, #0x20]
    mov r1, #0
    strh r1, [r12, #0x22]
    strh r1, [r12, #0x24]
    mov r1, #0x80
    strh r1, [r12, #0x26]
    mov r1, #0
    str r1, [r12, #0x28]
    str r1, [r12, #0x2C]
    @ DISPCNT mode3 + BG2
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
