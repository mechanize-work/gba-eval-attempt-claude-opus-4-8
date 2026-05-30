.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r1, =0x05000000
    ldr r2, =0x001F
    strh r2, [r1]
    ldr r2, =0x03E0
    strh r2, [r1, #2]
    ldr r0, =0x06000000
    ldr r1, =0x01010101
    mov r3, #0
mapf:
    str r1, [r0], #4
    add r3, r3, #1
    cmp r3, #64
    blt mapf
    ldr r0, =0x06004040
    mov r3, #0
tilef:
    str r1, [r0], #4
    add r3, r3, #1
    cmp r3, #16
    blt tilef
    ldr r2, =0x04000020
    ldr r1, =0x0100
    strh r1, [r2]
    mov r1, #0
    strh r1, [r2, #2]
    strh r1, [r2, #4]
    ldr r1, =0x0100
    strh r1, [r2, #6]
    ldr r2, =0x04000028
    mov r1, #0
    str r1, [r2]
    str r1, [r2, #4]
    ldr r2, =0x0400000C
    ldr r1, =0x0004           @ char base1, size0, bit13=0 (transparent overflow)
    strh r1, [r2]
    ldr r2, =0x04000000
    ldr r1, =0x0402
    strh r1, [r2]
forever:
    b forever
    .ltorg
