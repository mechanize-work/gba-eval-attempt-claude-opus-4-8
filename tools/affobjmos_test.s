.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ OBJ palette[1..8] = R = i*3
    ldr r0, =0x05000200
    mov r2, #1
pl: lsl r1, r2, #1
    add r1, r1, r2
    add r6, r0, r2, lsl #1
    strh r1, [r6]
    add r2, r2, #1
    cmp r2, #9
    blt pl
    @ OBJ tile0 (4bpp): each row = pixels 0..7 -> index 1..8 -> word 0x87654321
    ldr r0, =0x06010000
    ldr r1, =0x87654321
    mov r3, #8
1:  str r1, [r0], #4
    str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ OAM: sprite0 affine 16x16 at (100,76), mosaic; sprites1-3 disabled; affine params group0
    ldr r0, =0x07000000
    ldr r1, =0x114C          @ attr0 y=76 + affine(0x100) + mosaic(0x1000)
    strh r1, [r0]
    ldr r1, =0x4064          @ attr1 x=100 size1 paramgroup0
    strh r1, [r0, #2]
    ldr r1, =0x0000
    strh r1, [r0, #4]
    ldr r1, =0x0080          @ PA = 0x80 (0.5 -> 2x zoom)
    strh r1, [r0, #6]
    ldr r1, =0x0200          @ sprite1 disabled
    strh r1, [r0, #8]
    mov r1, #0
    strh r1, [r0, #0xE]      @ PB=0
    ldr r1, =0x0200          @ sprite2 disabled
    strh r1, [r0, #0x10]
    mov r1, #0
    strh r1, [r0, #0x16]     @ PC=0
    ldr r1, =0x0200          @ sprite3 disabled
    strh r1, [r0, #0x18]
    ldr r1, =0x0080          @ PD = 0x80
    strh r1, [r0, #0x1E]
    @ MOSAIC OBJ h=4 (bits8-11=3)
    ldr r1, =0x0300
    strh r1, [r12, #0x4C]
    @ DISPCNT OBJ + 1D
    ldr r1, =0x1040
    strh r1, [r12]
forever:
    b forever
