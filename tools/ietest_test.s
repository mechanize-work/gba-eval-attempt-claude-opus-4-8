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
    ldr r10, =0x04000200
    ldr r1, =0xFFFF
    strh r1, [r10]             @ IE = 0xFFFF
    ldrh r2, [r10]             @ read IE
    mov r1, #0
    strh r1, [r10]             @ restore IE=0
    ldr r3, =0x05000000
    strh r2, [r3]              @ backdrop = IE readback
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
