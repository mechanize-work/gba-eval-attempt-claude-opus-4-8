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
    ldr r1, =0x03E0
    strh r1, [r0, #4]        @ [2] green
    ldr r1, =0x7C00
    strh r1, [r0, #6]        @ [3] blue
    @ tn0+tn2 (0x06010000, 128 bytes) = red
    ldr r0, =0x06010000
    ldr r1, =0x01010101
    mov r3, #32
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ tn32+tn34 (0x06010400) = green
    ldr r0, =0x06010400
    ldr r1, =0x02020202
    mov r3, #32
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    @ tn64+tn66 (0x06010800) = blue
    ldr r0, =0x06010800
    ldr r1, =0x03030303
    mov r3, #32
3:  str r1, [r0], #4
    subs r3, r3, #1
    bne 3b
    ldr r0, =0x07000000
    ldr r1, =0x2050         @ attr0 y80 + 256color
    strh r1, [r0]
    ldr r1, =0x4064         @ attr1 x100 + size1 (16x16)
    strh r1, [r0, #2]
    ldr r1, =0x0000         @ attr2 tn0
    strh r1, [r0, #4]
    ldr r1, =0x1000         @ DISPCNT mode0 OBJ, 2D (bit6=0)
    strh r1, [r12]
forever:
    b forever
