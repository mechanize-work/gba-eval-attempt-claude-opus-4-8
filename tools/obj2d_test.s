.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    @ OBJ palette idx1..4 = green,blue,red,yellow
    ldr r1, =0x05000200
    ldr r2, =0x03E0
    strh r2, [r1, #2]
    ldr r2, =0x7C00
    strh r2, [r1, #4]
    ldr r2, =0x001F
    strh r2, [r1, #6]
    ldr r2, =0x03FF
    strh r2, [r1, #8]
    @ tile0 green
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r3, #0
t0: str r1, [r0], #4
    add r3, r3, #1
    cmp r3, #8
    blt t0
    @ tile1 blue (0x06010020)
    ldr r1, =0x22222222
    mov r3, #0
t1: str r1, [r0], #4
    add r3, r3, #1
    cmp r3, #8
    blt t1
    @ tile32 red (0x06010400)
    ldr r0, =0x06010400
    ldr r1, =0x33333333
    mov r3, #0
t32: str r1, [r0], #4
    add r3, r3, #1
    cmp r3, #8
    blt t32
    @ tile33 yellow (0x06010420)
    ldr r1, =0x44444444
    mov r3, #0
t33: str r1, [r0], #4
    add r3, r3, #1
    cmp r3, #8
    blt t33
    @ OAM: 16x16 sprite at (50,50), tile0
    ldr r2, =0x07000000
    ldr r1, =0x0032
    strh r1, [r2]
    ldr r1, =0x4032
    strh r1, [r2, #2]
    mov r1, #0
    strh r1, [r2, #4]
    ldr r1, =0x05000000
    ldr r2, =0x0000
    strh r2, [r1]            @ backdrop black
    @ DISPCNT mode0 + OBJ, 2D mapping (bit6=0)
    ldr r2, =0x04000000
    ldr r1, =0x1000
    strh r1, [r2]
forever:
    b forever
    .ltorg
