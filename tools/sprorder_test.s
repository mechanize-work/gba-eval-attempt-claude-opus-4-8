.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ OBJ palette [1]=red [2]=blue
    ldr r0, =0x05000200
    ldr r1, =0x001F
    strh r1, [r0, #2]
    ldr r1, =0x7C00
    strh r1, [r0, #4]
    @ OBJ tile0 = idx1 (red), tile1 = idx2 (blue) at 0x06010000
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
    @ OAM: sprite0 (tile0 red) and sprite1 (tile1 blue) both at (100,80) prio0
    ldr r0, =0x07000000
    ldr r1, =0x0050          @ attr0 y=80
    strh r1, [r0]
    ldr r1, =0x0064          @ attr1 x=100
    strh r1, [r0, #2]
    ldr r1, =0x0000          @ attr2 tile0 prio0
    strh r1, [r0, #4]
    @ sprite1
    ldr r1, =0x0050
    strh r1, [r0, #8]
    ldr r1, =0x0064
    strh r1, [r0, #0xA]
    ldr r1, =0x0001          @ attr2 tile1 prio0
    strh r1, [r0, #0xC]
    @ DISPCNT mode0 + OBJ(0x1000) + 1D map(0x40)
    ldr r1, =0x1140
    strh r1, [r12]
forever:
    b forever
