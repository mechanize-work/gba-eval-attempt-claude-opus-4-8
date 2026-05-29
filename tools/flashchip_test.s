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
    ldr r6, =0x0E001000        @ a different sector
    @ program 0x42 to Flash[0]
    mov r1, #0xAA
    strb r1, [r4]
    mov r1, #0x55
    strb r1, [r5]
    mov r1, #0xA0
    strb r1, [r4]
    mov r1, #0x42
    strb r1, [r0]
    @ program 0x37 to Flash[0x1000]
    mov r1, #0xAA
    strb r1, [r4]
    mov r1, #0x55
    strb r1, [r5]
    mov r1, #0xA0
    strb r1, [r4]
    mov r1, #0x37
    strb r1, [r6]
    @ chip erase: AA,55,80,AA,55,10@5555
    mov r1, #0xAA
    strb r1, [r4]
    mov r1, #0x55
    strb r1, [r5]
    mov r1, #0x80
    strb r1, [r4]
    mov r1, #0xAA
    strb r1, [r4]
    mov r1, #0x55
    strb r1, [r5]
    mov r1, #0x10
    strb r1, [r4]              @ chip erase
    ldrb r2, [r0]              @ expect 0xFF
    ldrb r3, [r6]             @ expect 0xFF
    and r2, r2, r3            @ both must be 0xFF -> 0xFF
    ldr r1, =0x05000000
    strh r2, [r1]            @ 0xFF -> color 0x00FF
    ldr r0, =0x04000000
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
sig:
    .asciz "FLASH1M_V"
