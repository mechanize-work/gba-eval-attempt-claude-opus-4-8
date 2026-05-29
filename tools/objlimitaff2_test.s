.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000200
    ldr r1, =0x001F           @ OBJ palette[1]=red
    strh r1, [r0, #2]
    @ fill OBJ tiles 0-63 with index1
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    ldr r3, =512
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ 9 affine sprites Y=80 64x64, matrix group0. idx0-7 X=0 dummies, idx8 X=120 real
    ldr r0, =0x07000000
    mov r4, #0
2:  ldr r1, =0x0180           @ attr0 Y=80 + affine(0x100)
    strh r1, [r0]
    cmp r4, #8
    movlt r2, #0
    movge r2, #120
    ldr r1, =0xC000           @ size3 + matrix group0
    orr r1, r1, r2
    strh r1, [r0, #2]
    mov r1, #0
    strh r1, [r0, #4]
    add r0, r0, #8
    add r4, r4, #1
    cmp r4, #9
    blt 2b
    @ group0 identity matrix: PA@6 PB@0xE PC@0x16 PD@0x1E
    ldr r0, =0x07000000
    ldr r1, =0x0100
    strh r1, [r0, #0x06]
    mov r1, #0
    strh r1, [r0, #0x0E]
    strh r1, [r0, #0x16]
    ldr r1, =0x0100
    strh r1, [r0, #0x1E]
    ldr r1, =0x1040           @ DISPCNT OBJ + 1D (budget 1210)
    strh r1, [r12]
forever:
    b forever
