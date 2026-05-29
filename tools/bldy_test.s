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
    mov r1, #0x1F
    strh r1, [r12, #0x54]      @ BLDY = 0x1F (write-only?)
    ldrh r2, [r12, #0x54]      @ read BLDY
    ldr r3, =0x05000000
    strh r2, [r3]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
