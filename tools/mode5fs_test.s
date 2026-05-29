.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
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
    @ frame0 buffer (0x06000000) = green
    ldr r0, =0x06000000
    ldr r1, =0x03E0
    ldr r4, =20480
    mov r3, #0
f0:
    strh r1, [r0], #2
    add r3, r3, #1
    cmp r3, r4
    blt f0
    @ frame1 buffer (0x0600A000) = blue
    ldr r0, =0x0600A000
    ldr r1, =0x7C00
    mov r3, #0
f1:
    strh r1, [r0], #2
    add r3, r3, #1
    cmp r3, r4
    blt f1
    @ DISPCNT = mode5 + BG2 + frame-select (bit4=0x10) -> show frame1 (blue)
    ldr r2, =0x04000000
    ldr r1, =0x0415
    strh r1, [r2]
forever:
    b forever
    .ltorg
