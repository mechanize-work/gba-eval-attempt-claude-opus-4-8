.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x05000200
    mov r3, #1
1:  add r5, r1, r3, lsl #1
    lsl r4, r3, #2            @ distinct-ish colors
    strh r4, [r5]
    add r3, r3, #1
    cmp r3, #16
    blt 1b
    @ OBJ tiles 0-3 (16x16=4 tiles 1D): per-column gradient via index = col+1
    ldr r1, =0x06010000
    ldr r2, =0x87654321
    mov r3, #0
2:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #128
    blt 2b
    ldr r1, =0x07000000
    @ group 0 matrix = HFLIP (PA=-0x100), group 1 = identity
    ldr r2, =0xFF00
    strh r2, [r1, #0x06]      @ grp0 PA = -0x100
    mov r2, #0
    strh r2, [r1, #0x0E]
    strh r2, [r1, #0x16]
    ldr r2, =0x0100
    strh r2, [r1, #0x1E]      @ grp0 PD
    ldr r2, =0x0100
    strh r2, [r1, #0x26]      @ grp1 PA @ base32+6=38=0x26
    mov r2, #0
    strh r2, [r1, #0x2E]      @ grp1 PB @ 46=0x2E
    strh r2, [r1, #0x36]      @ grp1 PC @ 54=0x36
    ldr r2, =0x0100
    strh r2, [r1, #0x3E]      @ grp1 PD @ 62=0x3E
    @ sprite uses matrix group 1
    ldr r2, =0x0140           @ y=64, affine(0x100), 16x16(shape0)... wait need bit8
    ldr r2, =0x0140
    strh r2, [r1]
    ldr r2, =0x4240           @ x=64, group1(0x200), size1(0x4000)
    strh r2, [r1, #2]
    mov r2, #0
    strh r2, [r1, #4]
    ldr r1, =0x1040
    strh r1, [r0]
forever:
    b forever
