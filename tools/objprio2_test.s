.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r1, =0x05000200
    ldr r2, =0x03E0
    strh r2, [r1, #2]        @ idx1 green
    ldr r2, =0x7C00
    strh r2, [r1, #4]        @ idx2 blue
    @ tile0 green
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r3, #0
t0: str r1, [r0], #4
    add r3, r3, #1
    cmp r3, #8
    blt t0
    @ tile1 blue
    ldr r1, =0x22222222
    mov r3, #0
t1: str r1, [r0], #4
    add r3, r3, #1
    cmp r3, #8
    blt t1
    @ OAM0: 8x8 green at (50,50) prio0
    ldr r2, =0x07000000
    ldr r1, =0x0032
    strh r1, [r2]
    ldr r1, =0x0032
    strh r1, [r2, #2]
    ldr r1, =0x0400
    strh r1, [r2, #4]        @ tile0 prio1
    @ OAM1: 8x8 blue at (54,50) prio0 (PRIOBITS in attr2 bits10-11)
    ldr r1, =0x0032
    strh r1, [r2, #8]
    ldr r1, =0x0036
    strh r1, [r2, #10]
    ldr r1, =0x0001          @ tile1, prio0
    strh r1, [r2, #12]
    ldr r1, =0x05000000
    mov r2, #0
    strh r2, [r1]            @ backdrop black
    ldr r2, =0x04000000
    ldr r1, =0x1040
    strh r1, [r2]
forever:
    b forever
    .ltorg
