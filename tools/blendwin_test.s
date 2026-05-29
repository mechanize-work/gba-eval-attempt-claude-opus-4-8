.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x001F            @ BG pal[1] = red
    strh r1, [r0, #2]
    @ BG tile 0 = index 1
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ BG0CNT screen base 8, prio 0
    ldr r1, =0x0800
    strh r1, [r12, #8]
    @ BLDCNT: 1st target BG0 (0x01), brighten mode (0x80)
    ldr r1, =0x0081
    strh r1, [r12, #0x50]
    @ BLDY = 16 (max brighten)
    mov r1, #16
    strh r1, [r12, #0x54]
    @ WIN0H: x1=0, x2=120 -> 0x0078
    ldr r1, =0x0078
    strh r1, [r12, #0x40]
    @ WIN0V: y1=0, y2=160 -> 0x00A0
    ldr r1, =0x00A0
    strh r1, [r12, #0x44]
    @ WININ: WIN0 inside = BG0 + blend (0x21)
    ldr r1, =0x0021
    strh r1, [r12, #0x48]
    @ WINOUT: outside = BG0 only, no blend (0x01)
    ldr r1, =0x0001
    strh r1, [r12, #0x4A]
    @ DISPCNT: mode0 BG0 WIN0
    ldr r1, =0x2100
    strh r1, [r12]
forever:
    b forever
