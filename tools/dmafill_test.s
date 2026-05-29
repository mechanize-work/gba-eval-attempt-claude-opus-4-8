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
    ldr r5, =0x12345678
    str r5, [r4]               @ fill value at 0x03000000
    mov r0, r4
    add r1, r4, #0x10
    str r0, [r12, #0xB0]       @ DMA0 src = 0x03000000
    str r1, [r12, #0xB4]       @ DMA0 dest = 0x03000010
    ldr r1, =0x85000004        @ cnt=4, src FIXED(bit24), dest inc, 32-bit, enable
    str r1, [r12, #0xB8]
    ldr r6, =0x06000000
    ldrh r2, [r4, #0x10]
    strh r2, [r6]              @ dest[0] low
    ldrh r2, [r4, #0x1C]
    strh r2, [r6, #2]          @ dest[3] low
    ldrh r2, [r4, #0x16]
    strh r2, [r6, #4]          @ dest[0] high (0x1234)
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
