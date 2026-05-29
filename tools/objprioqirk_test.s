.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x03E0
    strh r1, [r0, #2]        @ BG pal[1] green
    ldr r0, =0x05000200
    ldr r1, =0x001F
    strh r1, [r0, #2]        @ OBJ pal[1] red
    ldr r1, =0x7C00
    strh r1, [r0, #4]        @ OBJ pal[2] blue
    @ BG0 tile0 = green
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ OBJ tile0=red, tile1=blue
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r3, #8
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    ldr r1, =0x22222222
    mov r3, #8
3:  str r1, [r0], #4
    subs r3, r3, #1
    bne 3b
    @ BG0CNT prio 1
    ldr r1, =0x0801
    strh r1, [r12, #8]
    ldr r0, =0x07000000
    @ sprite A idx0 (100,80) red prio3
    ldr r1, =0x0050
    strh r1, [r0]
    ldr r1, =0x0064
    strh r1, [r0, #2]
    ldr r1, =0x0C00
    strh r1, [r0, #4]
    @ sprite B idx1 (100,80) blue prio0
    ldr r1, =0x0050
    strh r1, [r0, #8]
    ldr r1, =0x0064
    strh r1, [r0, #0xA]
    ldr r1, =0x0001
    strh r1, [r0, #0xC]
    @ DISPCNT BG0 + OBJ + 1D
    ldr r1, =0x1140
    orr r1, r1, #0x100
    strh r1, [r12]
forever:
    b forever
