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
    ldr r1, =0xFFFF
    strh r1, [r12, #0x04]      @ DISPSTAT = 0xFFFF
    ldrh r2, [r12, #0x04]      @ read DISPSTAT
    and r2, r2, #0xC0          @ bits 6-7
    mov r1, #0
    strh r1, [r12, #0x04]      @ restore DISPSTAT=0
    ldr r3, =0x05000000
    strh r2, [r3]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
