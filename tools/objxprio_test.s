.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000200
    ldr r1, =0x001F
    strh r1, [r0, #2]        @ OBJ pal[1] red
    ldr r1, =0x7C00
    strh r1, [r0, #4]        @ [2] blue
    @ OBJ tile0=red(idx1), tile1=blue(idx2)
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x22222222
    mov r3, #8
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    ldr r0, =0x07000000
    @ sprite0 (100,80) tile0 red, PRIORITY 3 (0xC00)
    ldr r1, =0x0050
    strh r1, [r0]
    ldr r1, =0x0064
    strh r1, [r0, #2]
    ldr r1, =0x0C00          @ tile0, prio3
    strh r1, [r0, #4]
    @ sprite1 (100,80) tile1 blue, PRIORITY 0
    ldr r1, =0x0050
    strh r1, [r0, #8]
    ldr r1, =0x0064
    strh r1, [r0, #0xA]
    ldr r1, =0x0001          @ tile1, prio0
    strh r1, [r0, #0xC]
    ldr r1, =0x1140          @ DISPCNT OBJ + 1D
    strh r1, [r12]
forever:
    b forever
