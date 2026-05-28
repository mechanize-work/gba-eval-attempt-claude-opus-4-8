.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ OBJ palette at 0x05000200: index 1 = white
    ldr r1, =0x05000200
    ldr r2, =0x7FFF
    strh r2, [r1, #2]
    @ OBJ tile 1 at 0x06010000 + 32 (4bpp): fill with index 1
    ldr r1, =0x06010020
    ldr r2, =0x11111111
    mov r3, #0
st:
    str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt st
    @ OAM sprite 0: affine, 16x16, at (100,60), tile 1, affine group 0
    ldr r1, =0x07000000
    @ attr0: y=60, affine(bit8), shape square(00), 16-color. = 60 | 0x100
    ldr r2, =0x013C
    strh r2, [r1]
    @ attr1: x=100, size 1 (16x16, bits14-15=01), affine group 0 = 100 | 0x4000
    ldr r2, =0x4064
    strh r2, [r1, #2]
    @ attr2: tile 1, palette 0 = 1
    mov r2, #1
    strh r2, [r1, #4]
    @ affine matrix group 0: PA@OAM+6, PB@+14, PC@+22, PD@+30. Rotation ~30deg scale 1.
    ldr r2, =0x00DD          @ PA ~0.86
    strh r2, [r1, #6]
    ldr r2, =0xFF80          @ PB ~-0.5
    strh r2, [r1, #14]
    ldr r2, =0x0080          @ PC ~0.5
    strh r2, [r1, #22]
    ldr r2, =0x00DD          @ PD
    strh r2, [r1, #30]
    @ DISPCNT: OBJ on (bit12), 1D mapping (bit6)
    ldr r1, =0x1040
    strh r1, [r0]
forever:
    b forever
