.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ OBJ palette: indices 1-4 distinct
    ldr r1, =0x05000200
    ldr r2, =0x001F
    strh r2, [r1, #2]
    ldr r2, =0x03E0
    strh r2, [r1, #4]
    ldr r2, =0x7C00
    strh r2, [r1, #6]
    ldr r2, =0x7FFF
    strh r2, [r1, #8]
    @ OBJ tile 1 (4bpp 8x8): a detailed pattern (each row different nibbles)
    ldr r1, =0x06010020
    ldr r2, =0x12341234
    mov r3, #0
st: str r2, [r1, r3]
    ldr r4, =0x11111111
    add r2, r2, r4
    add r3, r3, #4
    cmp r3, #32
    blt st
    @ MOSAIC reg (0x4C): OBJ mosaic h=4,v=4 -> bits8-11=3, bits12-15=3
    ldr r1, =0x3300
    strh r1, [r0, #0x4C]
    @ OAM sprite0: y=40, normal(no affine), mosaic(bit12), 32x32(shape0 size3), tile1
    ldr r1, =0x07000000
    ldr r2, =0xC028          @ y=40 | mosaic(0x1000) | size... attr0: y=0x28, bit12 mosaic, shape sq(00)
    strh r2, [r1]
    ldr r2, =0xC050          @ x=80, size3(32x32) bits14-15=11
    strh r2, [r1, #2]
    mov r2, #1               @ tile 1
    strh r2, [r1, #4]
    @ DISPCNT: OBJ on, 1D map
    ldr r1, =0x1040
    strh r1, [r0]
forever:
    b forever
