.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ BG palettes: use shared palette, index1 per BG via different palbank? simpler: 3 BGs each solid
    @ palette[1]=red, [2]=green, [3]=blue
    ldr r1, =0x05000000
    ldr r2, =0x001F
    strh r2, [r1, #2]
    ldr r2, =0x03E0
    strh r2, [r1, #4]
    ldr r2, =0x7C00
    strh r2, [r1, #6]
    @ BG0 tile@charbase0 index1(red), BG1 tile@charbase1 index2, BG2 tile@charbase2 index3
    ldr r1, =0x06000020
    ldr r2, =0x11111111
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 1b
    ldr r1, =0x06004020        @ charbase1
    ldr r2, =0x22222222
    mov r3, #0
2:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 2b
    ldr r1, =0x06008020        @ charbase2
    ldr r2, =0x33333333
    mov r3, #0
3:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 3b
    @ shared map @ 0x0600C000 (block24): all tile1
    ldr r1, =0x0600C000
    mov r4, #1
    mov r3, #0
4:  strh r4, [r1, r3]
    add r3, r3, #2
    cmp r3, #2048
    blt 4b
    @ BG0CNT: charbase0, screenbase24(0x1800), prio0
    ldr r1, =0x1800
    strh r1, [r0, #8]
    @ BG1CNT: charbase1(0x04), screenbase24, prio1
    ldr r1, =0x1805
    strh r1, [r0, #0xA]
    @ BG2CNT: charbase2(0x08), screenbase24, prio2
    ldr r1, =0x1806
    strh r1, [r0, #0xC]
    @ BLDCNT: alpha(0x40) | BG0 t1(0x01) | BG2 t2(0x400)
    ldr r1, =0x0441
    strh r1, [r0, #0x50]
    ldr r1, =0x0808
    strh r1, [r0, #0x52]
    @ DISPCNT mode0 | BG0|BG1|BG2
    ldr r1, =0x0700
    strh r1, [r0]
forever:
    b forever
