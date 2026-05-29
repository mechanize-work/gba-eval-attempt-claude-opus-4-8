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
    ldr r6, =0x06000000
    ldr r4, =0x08008000
    ldrh r2, [r4]              @ 16-bit past ROM -> expect 0x4000
    strh r2, [r6]
    ldr r4, =0x0800C000
    ldrh r2, [r4]              @ expect 0x6000
    strh r2, [r6, #2]
    ldr r4, =0x08008000
    ldr r2, [r4]               @ 32-bit -> low 0x4000 high 0x4001
    strh r2, [r6, #4]
    mov r2, r2, lsr #16
    strh r2, [r6, #6]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
