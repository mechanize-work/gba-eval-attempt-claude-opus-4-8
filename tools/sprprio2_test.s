.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000202
    ldr r1, =0x001F
    strh r1, [r0]
    ldr r1, =0x7C00
    strh r1, [r0, #2]
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r2, #8
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b
    ldr r1, =0x22222222
    mov r2, #8
2:  str r1, [r0], #4
    subs r2, r2, #1
    bne 2b
    ldr r0, =0x07000000
    ldr r1, =0x0032
    strh r1, [r0]
    ldr r1, =0x0032
    strh r1, [r0, #2]
    ldr r1, =0x0400
    strh r1, [r0, #4]          @ spr0 tile0 red, PRIORITY 1
    ldr r1, =0x0032
    strh r1, [r0, #8]
    ldr r1, =0x0036
    strh r1, [r0, #10]
    ldr r1, =0x0001
    strh r1, [r0, #12]         @ spr1 tile1 blue, PRIORITY 0
    ldr r1, =0x1040
    strh r1, [r12]
forever:
    b forever
