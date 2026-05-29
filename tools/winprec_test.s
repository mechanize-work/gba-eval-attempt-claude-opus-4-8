.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x06000000
    ldr r1, =0x001F001F
    ldr r2, =19200
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b                     @ BG2 bitmap = red
    ldr r1, =0x0078
    strh r1, [r12, #0x40]      @ WIN0H x 0-120
    ldr r1, =0x3CB4
    strh r1, [r12, #0x42]      @ WIN1H x 60-180
    ldr r1, =0x00A0
    strh r1, [r12, #0x44]      @ WIN0V
    strh r1, [r12, #0x46]      @ WIN1V
    mov r1, #0x04
    strh r1, [r12, #0x48]      @ WININ: win0=BG2, win1=none
    mov r1, #0
    strh r1, [r12, #0x4A]      @ WINOUT=none
    ldr r1, =0x6403            @ mode3 + BG2 + win0 + win1
    strh r1, [r12]
forever:
    b forever
