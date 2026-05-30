.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r1, =0x05000000
    ldr r2, =0x03E0           @ backdrop green (0,31,0)
    strh r2, [r1]
    ldr r2, =0x04000050
    ldr r1, =0x00E0           @ BLDCNT: BD 1st(0x20) + darken(0xC0)
    strh r1, [r2]
    ldr r2, =0x04000054
    mov r1, #8                @ BLDY = 8
    strh r1, [r2]
    ldr r2, =0x04000000
    mov r1, #0                @ DISPCNT=0, backdrop shows
    strh r1, [r2]
forever:
    b forever
    .ltorg
