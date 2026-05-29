.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    mov r1, #0
    strh r1, [r0]
    ldr r1, =0x001F
    strh r1, [r0, #2]          @ pal[1]=red
    ldr r1, =0x03E0
    strh r1, [r0, #4]          @ pal[2]=green
    ldr r1, =0x7C00
    strh r1, [r0, #6]          @ pal[3]=blue
    ldr r1, =0x7FFF
    strh r1, [r0, #8]          @ pal[4]=white
    ldr r1, =0x03FF
    strh r1, [r0, #10]         @ pal[5]=yellow
    ldr r0, =0x06000040        @ tile 1 (8bpp = 64 bytes)
    ldr r1, =0x04030201
    str r1, [r0]
    ldr r1, =0x08070605
    str r1, [r0, #4]
    add r0, r0, #8
    ldr r1, =0x01010101
    mov r2, #14
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b
    ldr r0, =0x06004000
    ldr r1, =0x00010001
    mov r2, #512
2:  str r1, [r0], #4
    subs r2, r2, #1
    bne 2b
    ldr r1, =0x0880            @ BG0CNT screen base 8, 8bpp(bit7)
    strh r1, [r12, #0x08]
    ldr r1, =0x0100            @ DISPCNT mode0 + BG0
    strh r1, [r12]
forever:
    b forever
