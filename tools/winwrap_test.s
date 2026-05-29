.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ fill mode-3 VRAM with red (0x001F in BGR555)
    ldr r0, =0x06000000
    ldr r1, =0x001F001F
    ldr r2, =19200
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b
    @ window 0: x1=100, x2=50 (x1 > x2 garbage case)
    ldr r1, =0x6432
    strh r1, [r12, #0x40]      @ WIN0H
    ldr r1, =0x00A0
    strh r1, [r12, #0x44]      @ WIN0V y1=0 y2=160
    mov r1, #0x04
    strh r1, [r12, #0x48]      @ WININ: BG2 inside win0
    mov r1, #0x00
    strh r1, [r12, #0x4A]      @ WINOUT: nothing
    ldr r1, =0x2403            @ DISPCNT mode3 + BG2 + win0
    strh r1, [r12]
forever:
    b forever
