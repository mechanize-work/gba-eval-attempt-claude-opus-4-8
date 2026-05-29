.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r11, =0x04000204
    ldr r1, =0xFFFF
    strh r1, [r11]
    ldrh r2, [r11]
    mov r1, #0
    strh r1, [r11]
    ldr r3, =0x05000000
    strh r2, [r3]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
