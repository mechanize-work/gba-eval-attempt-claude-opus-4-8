.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x001F          @ palette[1] red
    strh r1, [r0, #2]
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x0800
    strh r1, [r12, #8]
    @ WIN0H: X1=100, X2=140 -> 0x648C
    ldr r1, =0x648C
    strh r1, [r12, #0x40]
    @ WIN0V: Y1=0, Y2=160 -> 0x00A0
    ldr r1, =0x00A0
    strh r1, [r12, #0x44]
    @ WININ: WIN0 -> BG0 (0x01)
    ldr r1, =0x0001
    strh r1, [r12, #0x48]
    @ WINOUT: nothing
    ldr r1, =0x0000
    strh r1, [r12, #0x4A]
    @ DISPCNT mode0 BG0 WIN0
    ldr r1, =0x2100
    strh r1, [r12]
forever:
    b forever
