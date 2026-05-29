.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ palette 1..8 distinct
    ldr r1, =0x05000000
    add r5, r1, #2
    ldr r2, =0x001F
    strh r2, [r5], #2
    ldr r2, =0x03E0
    strh r2, [r5], #2
    ldr r2, =0x7C00
    strh r2, [r5], #2
    ldr r2, =0x7FFF
    strh r2, [r5], #2
    ldr r2, =0x03FF
    strh r2, [r5], #2
    ldr r2, =0x7FE0
    strh r2, [r5], #2
    ldr r2, =0x7C1F
    strh r2, [r5], #2
    ldr r2, =0x4210
    strh r2, [r5], #2
    @ BG0 tile1 = per-column gradient
    ldr r1, =0x06000020
    ldr r2, =0x87654321
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 1b
    ldr r1, =0x06004000
    mov r4, #1
    mov r3, #0
2:  strh r4, [r1, r3]
    add r3, r3, #2
    cmp r3, #2048
    blt 2b
    ldr r1, =0x0800
    strh r1, [r0, #8]          @ BG0CNT
    mov r1, #3
    strh r1, [r0, #0x4C]       @ MOSAIC BG H=4
    @ WIN0: x 0..122 (edge mid-mosaic-block), full height
    ldr r1, =0x007A           @ WIN0H = 0..122
    strh r1, [r0, #0x40]
    ldr r1, =0x00A0
    strh r1, [r0, #0x44]       @ WIN0V full
    mov r1, #1
    strh r1, [r0, #0x48]       @ WININ: WIN0 = BG0
    mov r1, #0
    strh r1, [r0, #0x4A]       @ WINOUT: nothing
    ldr r1, =0x2100           @ DISPCNT mode0|BG0|WIN0
    strh r1, [r0]
forever:
    b forever
