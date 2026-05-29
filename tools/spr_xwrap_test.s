.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000202
    ldr r1, =0x03E0
    strh r1, [r0]
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r3, #128
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r0, =0x07000000
    ldr r1, =0x0028          @ attr0: y=40
    strh r1, [r0]
    ldr r1, =0x81F4          @ attr1: x=500(0x1F4), size 2 (32x32)
    strh r1, [r0, #2]
    mov r1, #0
    strh r1, [r0, #4]
    ldr r1, =0x1040
    strh r1, [r12]
forever:
    b forever
