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
    ldr r4, =0x03000000
    ldr r1, =0x12345678
    str r1, [r4]
    str r4, [r12, #0xB0]       @ DMA0 src
    add r1, r4, #0x10
    str r1, [r12, #0xB4]       @ DMA0 dst
    ldr r1, =0x84000001        @ enable + 32-bit + immediate + count 1
    str r1, [r12, #0xB8]
    ldrh r2, [r12, #0xBA]      @ DMACNT_H after DMA (enable should clear)
    ldr r6, =0x06000000
    strh r2, [r6]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
