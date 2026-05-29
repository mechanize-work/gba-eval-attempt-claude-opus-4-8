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
    ldr r0, =0x06000000
    ldr r1, =0x7C007C00
    ldr r2, =19200
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b                     @ bitmap = blue
    ldr r0, =0x06014000        @ OBJ tile 512 (bitmap-mode OBJ base)
    ldr r1, =0x11111111
    mov r2, #8
2:  str r1, [r0], #4
    subs r2, r2, #1
    bne 2b
    ldr r0, =0x07000000
    ldr r1, =0x0032
    strh r1, [r0]              @ y=50
    ldr r1, =0x0032
    strh r1, [r0, #2]          @ x=50
    ldr r1, =512
    strh r1, [r0, #4]          @ tile 512
    ldr r1, =0x1443
    strh r1, [r12]             @ mode3 + BG2 + OBJ + 1D
forever:
    b forever
