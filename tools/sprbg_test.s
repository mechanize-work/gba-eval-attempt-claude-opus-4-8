.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ BG palette[1]=blue
    ldr r0, =0x05000000
    ldr r1, =0x7C00
    strh r1, [r0, #2]
    @ OBJ palette[1]=red
    ldr r0, =0x05000200
    ldr r1, =0x001F
    strh r1, [r0, #2]
    @ BG0 tile0 = idx1 (blue)
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ OBJ tile0 = idx1 (red)
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r3, #8
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    @ BG0CNT prio1 sb8 = 0x0801
    ldr r1, =0x0801
    strh r1, [r12, #8]
    @ sprite0 at (100,80) tile0 prio1 (attr2 prio bits 10-11 = 1<<10 = 0x400)
    ldr r0, =0x07000000
    ldr r1, =0x0050
    strh r1, [r0]
    ldr r1, =0x0064
    strh r1, [r0, #2]
    ldr r1, =0x0400          @ tile0, prio1
    strh r1, [r0, #4]
    @ DISPCNT mode0 + BG0(0x100) + OBJ(0x1000) + 1D(0x40)
    ldr r1, =0x1140
    orr r1, r1, #0x100
    strh r1, [r12]
forever:
    b forever
