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
    @ program 0x42 to Flash[0]
    mov r1, #0xAA
    strb r1, [r4]
    mov r1, #0x55
    strb r1, [r5]
    mov r1, #0xA0
    strb r1, [r4]
    mov r1, #0x42
    strb r1, [r0]
    ldrb r6, [r0]             @ expect 0x42
    @ sector erase sector 0: AA,55,80,AA,55,30@sector
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
    mov r1, #0x30
    strb r1, [r0]             @ erase sector at offset 0
    ldrb r7, [r0]             @ expect 0xFF
    mov r2, r6, lsl #8
    orr r2, r2, r7
    ldr r1, =0x7FFF
    and r2, r2, r1
    ldr r1, =0x05000000
    strh r2, [r1]
    ldr r0, =0x04000000
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
sig:
    .asciz "FLASH1M_V"
