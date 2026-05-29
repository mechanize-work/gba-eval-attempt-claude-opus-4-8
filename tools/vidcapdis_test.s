.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r4, =0x03000000
    ldr r1, =0x12345678
    str r1, [r4]
    str r4, [r12, #0xD4]
    ldr r5, =0x02000000
    str r5, [r12, #0xD8]
    ldr r1, =0xB7000001
    str r1, [r12, #0xDC]
    mov r1, #0
    strh r1, [r12]
    ldr r0, =0x05000000
loop:
    ldrh r2, [r12, #0xDE]      @ DMA3 control high (DMACNT_H)
    tst r2, #0x8000            @ enable bit
    moveq r1, #0x1F            @ red = auto-disabled
    movne r1, #0x3E0           @ green = still enabled
    strh r1, [r0]
    b loop
