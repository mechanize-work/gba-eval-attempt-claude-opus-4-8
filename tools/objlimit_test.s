.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ OBJ palette[1] = red
    ldr r0, =0x05000200
    ldr r1, =0x001F
    strh r1, [r0, #2]
    @ fill OBJ tiles 0-63 (2048 bytes) with color 1
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    ldr r3, =512
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ OAM: 26 sprites Y=80 64x64. idx0-24 dummies X=0, idx25 real X=120
    ldr r0, =0x07000000
    mov r4, #0
2:  mov r1, #0x50            @ attr0 Y=80
    strh r1, [r0]
    cmp r4, #25
    movlt r2, #0            @ dummy X=0
    movge r2, #120          @ real X=120
    ldr r1, =0xC000
    orr r1, r1, r2          @ size3 + X
    strh r1, [r0, #2]
    mov r1, #0
    strh r1, [r0, #4]
    add r0, r0, #8
    add r4, r4, #1
    cmp r4, #26
    blt 2b
    ldr r1, =0x1040          @ DISPCNT OBJ + 1D
    strh r1, [r12]
forever:
    b forever
