.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000202
    ldr r1, =0x001F
    strh r1, [r0]              @ OBJ pal[1]=red
    ldr r1, =0x7C00
    strh r1, [r0, #2]          @ OBJ pal[2]=blue
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r2, #8
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b                     @ OBJ tile0 = idx1 (red)
    ldr r1, =0x22222222
    mov r2, #8
2:  str r1, [r0], #4
    subs r2, r2, #1
    bne 2b                     @ OBJ tile1 = idx2 (blue)
    ldr r0, =0x07000000
    ldr r1, =0x0032
    strh r1, [r0]              @ spr0 y=50
    ldr r1, =0x0032
    strh r1, [r0, #2]          @ spr0 x=50 8x8
    mov r1, #0
    strh r1, [r0, #4]          @ spr0 tile0 red
    ldr r1, =0x0032
    strh r1, [r0, #8]          @ spr1 y=50
    ldr r1, =0x0036
    strh r1, [r0, #10]         @ spr1 x=54 8x8
    mov r1, #1
    strh r1, [r0, #12]         @ spr1 tile1 blue
    ldr r1, =0x1040
    strh r1, [r12]
forever:
    b forever
