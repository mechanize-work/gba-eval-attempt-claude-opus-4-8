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
    str r1, [r4]               @ src pattern
    ldr r5, =0x02000000
    mov r1, #0
    str r1, [r5]               @ clear dst
    str r4, [r12, #0xD4]       @ DMA3 src
    str r5, [r12, #0xD8]       @ DMA3 dst
    ldr r1, =0xB7000001        @ enable+special(timing3)+repeat+32bit+src-fixed+count1
    str r1, [r12, #0xDC]
    mov r1, #0
    strh r1, [r12]
    ldr r0, =0x06000000
loop:
    ldrh r2, [r5]              @ dst[0] (written by video capture?)
    strh r2, [r0]
    ldr r1, =0x0403
    strh r1, [r12]
    b loop
