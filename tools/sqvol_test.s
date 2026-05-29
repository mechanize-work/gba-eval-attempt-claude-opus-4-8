.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ master enable FIRST
    mov r1, #0x80
    strh r1, [r12, #0x84]
    @ ch1: duty 50%, env vol 15 no decay
    ldr r1, =0xF080
    strh r1, [r12, #0x62]
    @ freq + trigger
    ldr r1, =0x8500
    strh r1, [r12, #0x64]
    @ SOUNDCNT_L = VOLPLACEHOLDER (ch1 L/R + master vol)
    ldr r1, =0xVOLL
    strh r1, [r12, #0x80]
    @ SOUNDCNT_H = ratio
    ldr r1, =0xRATIO
    strh r1, [r12, #0x82]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
