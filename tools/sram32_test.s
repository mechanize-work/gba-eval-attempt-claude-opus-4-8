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
    mov r1, #0x11
    strb r1, [r4]
    mov r1, #0x22
    strb r1, [r4, #1]
    mov r1, #0x33
    strb r1, [r4, #2]
    mov r1, #0x44
    strb r1, [r4, #3]
    ldr r2, [r4]               @ 32-bit read of SRAM
    ldr r6, =0x06000000
    strh r2, [r6]
    mov r2, r2, lsr #16
    strh r2, [r6, #2]
    ldrh r2, [r4]              @ 16-bit read
    strh r2, [r6, #4]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
