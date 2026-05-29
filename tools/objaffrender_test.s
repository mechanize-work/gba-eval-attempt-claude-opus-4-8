.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ OBJ pal[1]=red [2]=blue
    ldr r0, =0x05000200
    ldr r1, =0x001F
    strh r1, [r0, #2]
    ldr r1, =0x7C00
    strh r1, [r0, #4]
    @ tile0=blue, tiles1-3=red (16x16 1D = 4 tiles)
    ldr r0, =0x06010000
    ldr r1, =0x22222222
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x11111111
    mov r3, #24
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    @ ObjAffineSet: 45deg, scale 1.0 -> OAM group0 matrix (dest=OAM+6, r3=8)
    adr r0, affsrc
    ldr r1, =0x07000006
    mov r2, #1
    mov r3, #8
    swi 0x0F0000
    @ sprite0: y=60 affine+double, x=100 size1(16x16) affidx0, tile0
    ldr r0, =0x07000000
    ldr r1, =0x033C
    strh r1, [r0]
    ldr r1, =0x4064
    strh r1, [r0, #2]
    mov r1, #0
    strh r1, [r0, #4]
    ldr r1, =0x1040
    strh r1, [r12]
forever:
    b forever
.align 2
affsrc:
    .hword 0x0100, 0x0100, 0x2000, 0x0000
