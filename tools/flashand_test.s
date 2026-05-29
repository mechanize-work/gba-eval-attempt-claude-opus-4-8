.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x0E000000
    ldr r4, =0x0E005555
    ldr r5, =0x0E002AAA
    @ program 0x3C
    mov r1, #0xAA
    strb r1, [r4]
    mov r1, #0x55
    strb r1, [r5]
    mov r1, #0xA0
    strb r1, [r4]
    mov r1, #0x3C
    strb r1, [r0]
    @ program 0x5A (no erase) -> AND should give 0x18
    mov r1, #0xAA
    strb r1, [r4]
    mov r1, #0x55
    strb r1, [r5]
    mov r1, #0xA0
    strb r1, [r4]
    mov r1, #0x5A
    strb r1, [r0]
    ldrb r2, [r0]             @ AND=0x18, overwrite=0x5A
    ldr r1, =0x05000000
    strh r2, [r1]
    ldr r0, =0x04000000
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
sig:
    .asciz "FLASH1M_V"
