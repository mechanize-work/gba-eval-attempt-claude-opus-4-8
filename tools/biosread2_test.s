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
    mov r0, #0
    ldr r2, [r0]               @ word at BIOS[0]
    strh r2, [r6]
    mov r2, r2, lsr #16
    strh r2, [r6, #2]
    ldr r0, =0x00001000
    ldr r2, [r0]               @ word at BIOS[0x1000] (diff addr)
    strh r2, [r6, #4]
    mov r2, r2, lsr #16
    strh r2, [r6, #6]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
