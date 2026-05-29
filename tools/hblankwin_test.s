@ Per-line window via HBlank IRQ: WIN0H right edge = VCOUNT -> triangular reveal.
@ Inside WIN0 = BG0 (red), outside = backdrop. Tests per-line window re-eval.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4

main:
    ldr r0, =0x04000000

    @ backdrop black, palette[1]=red
    ldr r1, =0x05000000
    mov r2, #0
    strh r2, [r1]
    ldr r2, =0x001F
    strh r2, [r1, #2]

    @ BG0 tile1 @ 0x06000020 all index1 (red)
    ldr r1, =0x06000020
    ldr r2, =0x11111111
    mov r3, #0
trow:
    str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt trow
    @ map @ 0x06004000 all tile1
    ldr r1, =0x06004000
    mov r4, #1
    mov r3, #0
tmap:
    strh r4, [r1, r3]
    add r3, r3, #2
    cmp r3, #2048
    blt tmap

    ldr r1, =0x0800
    strh r1, [r0, #8]          @ BG0CNT screenbase block8

    @ WIN0V = full height (top0, bottom160)
    ldr r1, =0x00A0
    strh r1, [r0, #0x44]
    @ WININ: WIN0 shows BG0 (bit0)
    mov r1, #1
    strh r1, [r0, #0x48]
    @ WINOUT: nothing
    mov r1, #0
    strh r1, [r0, #0x4A]

    @ IRQ handler
    ldr r1, =0x03007FFC
    ldr r2, =irq_handler
    str r2, [r1]
    mov r1, #0x10
    strh r1, [r0, #4]          @ DISPSTAT HBlank IRQ
    ldr r3, =0x04000200
    mov r1, #2
    strh r1, [r3]              @ IE HBlank
    mov r1, #1
    strh r1, [r3, #8]          @ IME

    @ DISPCNT = mode0 | BG0(0x100) | WIN0(0x2000)
    ldr r1, =0x2100
    strh r1, [r0]
forever:
    b forever
    .ltorg

irq_handler:
    ldr r0, =0x04000202
    mov r1, #2
    strh r1, [r0]
    ldr r2, =0x03007FF8
    ldrh r3, [r2]
    orr r3, r3, #2
    strh r3, [r2]
    ldr r0, =0x04000000
    ldrh r1, [r0, #6]          @ VCOUNT
    strh r1, [r0, #0x40]       @ WIN0H = vcount (left=0, right=vcount)
    bx lr
    .ltorg
