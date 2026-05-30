.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r1, =0x05000000
    ldr r2, =0x001F          @ backdrop red
    strh r2, [r1]
    ldr r2, =0x03E0          @ idx1 green
    strh r2, [r1, #2]
    ldr r0, =0x06000020
    ldr r1, =0x11111111
    mov r3, #0
tf: str r1, [r0], #4
    add r3, r3, #1
    cmp r3, #8
    blt tf
    ldr r0, =0x06000800
    ldr r1, =0x00010001
    mov r3, #0
mf: str r1, [r0], #4
    add r3, r3, #1
    cmp r3, #512
    blt mf
    ldr r2, =0x04000008
    ldr r1, =0x0100
    strh r1, [r2]
    @ WIN0H = 0..160, WIN1H = 80..240 (overlap 80-159)
    ldr r2, =0x04000040
    ldr r1, =0x00A0
    strh r1, [r2]            @ WIN0H
    ldr r1, =0x50F0
    strh r1, [r2, #2]        @ WIN1H X1=80 X2=240
    ldr r1, =0x00A0
    strh r1, [r2, #4]        @ WIN0V
    strh r1, [r2, #6]        @ WIN1V
    @ WININ: WIN0=BG0(0x01), WIN1=nothing(0x00)
    ldr r2, =0x04000048
    ldr r1, =0x0001
    strh r1, [r2]
    mov r1, #0
    strh r1, [r2, #2]        @ WINOUT=0
    ldr r2, =0x04000000
    ldr r1, =0x6100          @ mode0+BG0+WIN0+WIN1
    strh r1, [r2]
forever:
    b forever
    .ltorg
