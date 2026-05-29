.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0
    strh r1, [r12]
    ldr r0, =0x06002000
    ldr r1, =0x1111
    strh r1, [r0]
    ldr r0, =0x06010000
    ldr r1, =0x2222
    strh r1, [r0]
    ldr r0, =0x06014000
    ldr r1, =0x3333
    strh r1, [r0]
    @ read mirrors
    ldr r0, =0x06022000
    ldrh r3, [r0]              @ mirror of 0x06002000 -> 0x1111
    ldr r0, =0x06018000
    ldrh r4, [r0]              @ mirror of 0x06010000 -> 0x2222
    ldr r0, =0x0601C000
    ldrh r5, [r0]              @ mirror of 0x06014000 -> 0x3333
    ldr r6, =0x06000000
    strh r3, [r6]
    strh r4, [r6, #2]
    strh r5, [r6, #4]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
