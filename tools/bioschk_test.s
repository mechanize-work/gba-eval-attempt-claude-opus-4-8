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
    swi 0x0D0000               @ GetBiosChecksum -> r0
    ldr r6, =0x06000000
    strh r0, [r6]
    mov r0, r0, lsr #16
    strh r0, [r6, #2]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
