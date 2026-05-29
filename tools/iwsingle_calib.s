.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r3, =0x03000000
    ldr r0, =100000
loop:
    str r2, [r3]               @ single EWRAM 32-bit store
    subs r0, r0, #1
    bne loop
    ldr r2, =0x05000000
    ldr r1, =0x001F
    strh r1, [r2]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
