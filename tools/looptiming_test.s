.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r11, =0x04000100
    mov r1, #0
    strh r1, [r11]
    mov r1, #0x80
    strh r1, [r11, #2]
    ldrh r2, [r11]
    mov r3, #1000
loop:
    subs r3, r3, #1
    bne loop
    ldrh r4, [r11]
    sub r5, r4, r2
    ldr r1, =0x05000000
    strh r5, [r1]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
