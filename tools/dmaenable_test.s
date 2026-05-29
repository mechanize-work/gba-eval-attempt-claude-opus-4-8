.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ source + dest buffers in EWRAM
    ldr r0, =0x02000000
    ldr r1, =0x12345678
    str r1, [r0]
    @ DMA3: immediate, 1 word, no repeat
    ldr r1, =0x02000000
    str r1, [r12, #0xD4]      @ src
    ldr r1, =0x02000100
    str r1, [r12, #0xD8]      @ dst
    ldr r1, =0x84000001       @ enable + immediate + 32bit, count 1
    str r1, [r12, #0xDC]
    @ read back DMA3CNT_H (0xDE) - enable bit should be CLEARED after immediate DMA
    ldrh r2, [r12, #0xDE]
    ldr r3, =0x05000000
    strh r2, [r3]             @ backdrop = DMA3CNT_H readback
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
