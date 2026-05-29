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
    ldr r4, =0x10000000
    ldrh r2, [r4]              @ unmapped 16-bit read -> open bus
    ldr r6, =0x06000000
    strh r2, [r6]
    ldr r2, [r4]               @ unmapped 32-bit read
    strh r2, [r6, #2]
    mov r2, r2, lsr #16
    strh r2, [r6, #4]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
