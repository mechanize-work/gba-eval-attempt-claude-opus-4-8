.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    adr r0, srcw
    ldr r1, =0x02000000
    ldr r2, =0x01000008    @ 8 words, fill mode (bit24)
    swi 0x0C0000
    ldr r0, =0x02000000
    ldrh r2, [r0, #8]      @ dst[2] should be filled = 0x5678
    ldr r3, =0x05000000
    strh r2, [r3]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
.align 2
srcw: .word 0x12345678
