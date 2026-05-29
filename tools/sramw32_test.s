.arm
.section .text
.global _start
_start:
    b main
    .ascii "SRAM_V100"
    .space 0xC0 - 4 - 9
main:
    ldr r12, =0x04000000
    mov r1, #0
    strh r1, [r12]
    ldr r4, =0x0E000000
    mov r1, #0xAA
    strb r1, [r4]
    strb r1, [r4, #1]
    strb r1, [r4, #2]
    strb r1, [r4, #3]          @ prefill all 4 bytes = 0xAA
    ldr r1, =0x11223344
    str r1, [r4]               @ 32-bit write
    ldrb r0, [r4]
    ldrb r1, [r4, #1]
    ldrb r2, [r4, #2]
    ldrb r3, [r4, #3]
    ldr r6, =0x06000000
    orr r0, r0, r1, lsl #8
    strh r0, [r6]              @ bytes 0,1
    orr r2, r2, r3, lsl #8
    strh r2, [r6, #2]          @ bytes 2,3
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
