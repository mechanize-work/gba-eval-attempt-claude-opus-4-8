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
    ldr r4, =0x0E005555
    mov r1, #0xAA
    strb r1, [r4]
    ldr r4, =0x0E002AAA
    mov r1, #0x55
    strb r1, [r4]
    ldr r4, =0x0E005555
    mov r1, #0x90
    strb r1, [r4]              @ enter ID mode
    ldr r4, =0x0E000000
    ldrb r2, [r4]
    ldrb r3, [r4, #1]
    ldr r0, =0x0E005555
    mov r1, #0xF0
    strb r1, [r0]              @ exit ID mode
    ldr r6, =0x06000000
    orr r2, r2, r3, lsl #8
    strh r2, [r6]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
flashsig:
    .ascii "FLASH_V123"
