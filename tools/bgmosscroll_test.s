@ BG mosaic + scroll: per-column gradient tile, mosaic mos_h=4, HOFS=2 (not a
@ multiple of 4). Tests whether mosaic blocks align to the screen (then +scroll)
@ or to the scrolled BG coordinate. Compare to oracle.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x05000000
    ldr r2, =0x001F
    strh r2, [r1, #2]          @1 red
    ldr r2, =0x03E0
    strh r2, [r1, #4]          @2 green
    ldr r2, =0x7C00
    strh r2, [r1, #6]          @3 blue
    ldr r2, =0x7FFF
    strh r2, [r1, #8]          @4 white
    ldr r2, =0x03FF
    strh r2, [r1, #10]         @5 cyan
    ldr r2, =0x7FE0
    strh r2, [r1, #12]         @6 yellow
    ldr r2, =0x7C1F
    strh r2, [r1, #14]         @7 magenta
    ldr r2, =0x4210
    strh r2, [r1, #16]         @8 grey
    @ BG0 tile1: columns 1..8 per row
    ldr r1, =0x06000020
    ldr r2, =0x87654321
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 1b
    @ map all tile 1
    ldr r1, =0x06004000
    mov r4, #1
    mov r3, #0
2:  strh r4, [r1, r3]
    add r3, r3, #2
    cmp r3, #2048
    blt 2b
    ldr r1, =0x0800
    strh r1, [r0, #8]          @ BG0CNT screenbase block8
    mov r1, #2
    strh r1, [r0, #0x10]       @ BG0HOFS = 2
    mov r1, #3
    strh r1, [r0, #0x4C]       @ MOSAIC BG H = 4
    ldr r1, =0x0140           @ wait, DISPCNT mode0|BG0|? -> 0x0100
    ldr r1, =0x0100
    strh r1, [r0]
forever:
    b forever
