.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ palette[1..8] = R = i*3
    ldr r0, =0x05000000
    mov r2, #1
pl: lsl r1, r2, #1
    add r1, r1, r2          @ i*3
    add r6, r0, r2, lsl #1
    strh r1, [r6]
    add r2, r2, #1
    cmp r2, #9
    blt pl
    @ affine tile0 @0x06000000: each row = bytes 1,2,3,4,5,6,7,8 (gradient)
    ldr r0, =0x06000000
    ldr r4, =0x04030201
    ldr r5, =0x08070605
    mov r3, #8
tl: str r4, [r0], #4
    str r5, [r0], #4
    subs r3, r3, #1
    bne tl
    @ BG2CNT: mosaic(0x40) + screen base 8(0x800), size0 = 0x0840
    ldr r1, =0x0840
    strh r1, [r12, #0xC]
    ldr r1, =0x0100
    strh r1, [r12, #0x20]
    mov r1, #0
    strh r1, [r12, #0x22]
    strh r1, [r12, #0x24]
    ldr r1, =0x0100
    strh r1, [r12, #0x26]
    mov r1, #0
    str r1, [r12, #0x28]
    str r1, [r12, #0x2C]
    @ MOSAIC h=4 (bits0-3=3)
    ldr r1, =0x0003
    strh r1, [r12, #0x4C]
    ldr r1, =0x0402
    strh r1, [r12]
forever:
    b forever
