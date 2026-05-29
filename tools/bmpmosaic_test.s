.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ fill row 80 of mode-3 bitmap with R = x & 0x1F (gradient)
    ldr r0, =0x06009600
    mov r2, #0
fill:
    and r1, r2, #0x1F
    strh r1, [r0], #2
    add r2, r2, #1
    cmp r2, #240
    blt fill
    @ BG2CNT mosaic enable (bit6 = 0x40)
    ldr r1, =0x0040
    strh r1, [r12, #0xC]
    @ MOSAIC: BG h=8 (bits0-3=7), v=1 -> 0x0007
    ldr r1, =0x0007
    strh r1, [r12, #0x4C]
    @ DISPCNT mode3 + BG2
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
