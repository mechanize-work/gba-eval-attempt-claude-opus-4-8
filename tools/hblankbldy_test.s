@ Per-line BLDY via HBlank IRQ: brightness coeff = VCOUNT>>3 -> vertical fade.
@ BG0 blue brightened toward white at the bottom. Tests per-line blend coeff.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4

main:
    ldr r0, =0x04000000
    @ palette[1] = blue
    ldr r1, =0x05000000
    ldr r2, =0x7C00
    strh r2, [r1, #2]
    @ BG0 tile1 all index1
    ldr r1, =0x06000020
    ldr r2, =0x11111111
    mov r3, #0
trow:
    str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt trow
    ldr r1, =0x06004000
    mov r4, #1
    mov r3, #0
tmap:
    strh r4, [r1, r3]
    add r3, r3, #2
    cmp r3, #2048
    blt tmap
    ldr r1, =0x0800
    strh r1, [r0, #8]          @ BG0CNT

    @ BLDCNT (0x50): brighten mode (bits6-7=10 -> 0x80), BG0 target1 (bit0)
    ldr r1, =0x0081
    strh r1, [r0, #0x50]

    @ IRQ handler
    ldr r1, =0x03007FFC
    ldr r2, =irq_handler
    str r2, [r1]
    mov r1, #0x10
    strh r1, [r0, #4]
    ldr r3, =0x04000200
    mov r1, #2
    strh r1, [r3]
    mov r1, #1
    strh r1, [r3, #8]

    ldr r1, =0x0100
    strh r1, [r0]             @ DISPCNT mode0|BG0
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
    ldrh r1, [r0, #6]         @ VCOUNT
    mov r1, r1, lsr #3        @ /8 -> 0..19
    ldr r2, =0x04000054       @ BLDY (separate base)
    strh r1, [r2]
    bx lr
    .ltorg
