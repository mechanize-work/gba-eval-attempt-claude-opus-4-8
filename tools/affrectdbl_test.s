@ Rectangular affine double-size sprite: 32x16 (shape H, size2), affine+double
@ -> 64x32 bounding box, identity matrix -> content centered. Tests rect affine dbl.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x05000202
    ldr r2, =0x001F           @ OBJ palette[1] red
    strh r2, [r1]
    @ fill OBJ tiles 0-15 (enough for 32x16=8 tiles) with index1
    ldr r1, =0x06010000
    ldr r2, =0x11111111
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #512
    blt 1b
    @ OAM[0]: 32x16 affine double-size at (40,40)
    ldr r1, =0x07000000
    ldr r2, =0x4340           @ attr0: Y=40, affine(0x100), double(0x200), shape H(0x4000)
    strh r2, [r1]
    ldr r2, =0x8028           @ attr1: X=40, size2(0x8000), matrix0
    strh r2, [r1, #2]
    mov r2, #0
    strh r2, [r1, #4]
    @ identity matrix group 0
    ldr r2, =0x0100
    strh r2, [r1, #0x06]      @ PA
    mov r2, #0
    strh r2, [r1, #0x0E]      @ PB
    strh r2, [r1, #0x16]      @ PC
    ldr r2, =0x0100
    strh r2, [r1, #0x1E]      @ PD
    ldr r1, =0x1040           @ DISPCNT mode0|OBJ|1D
    strh r1, [r0]
forever:
    b forever
