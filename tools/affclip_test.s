.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ OBJ palette: [1]=red [2]=blue
    ldr r0, =0x05000200
    ldr r1, =0x001F
    strh r1, [r0, #2]
    ldr r1, =0x7C00
    strh r1, [r0, #4]
    @ OBJ tiles: tile0 = color2(blue), tiles1-15 = color1(red). 32x32 4bpp = 16 tiles.
    ldr r0, =0x06010000
    ldr r1, =0x22222222
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x11111111
    mov r3, #120          @ 15 tiles * 8 words
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    @ OAM affine matrix 0: rotation ~30deg PA=222 PB=-128 PC=128 PD=222
    ldr r0, =0x07000000
    ldr r1, =222
    strh r1, [r0, #0x06]
    ldr r1, =0xFF80       @ -128
    strh r1, [r0, #0x0E]
    ldr r1, =128
    strh r1, [r0, #0x16]
    ldr r1, =222
    strh r1, [r0, #0x1E]
    @ sprite0: y=48 affine+double, x=88 size3(32x32) affidx0, tile0
    ldr r1, =0x0130
    strh r1, [r0]
    ldr r1, =0xC058
    strh r1, [r0, #2]
    ldr r1, =0x0000
    strh r1, [r0, #4]
    @ DISPCNT OBJ + 1D
    ldr r1, =0x1040
    strh r1, [r12]
forever:
    b forever
