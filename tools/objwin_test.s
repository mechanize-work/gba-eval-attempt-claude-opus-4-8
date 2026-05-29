.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000002
    ldr r1, =0x001F
    strh r1, [r0]              @ BG pal[1]=red
    ldr r0, =0x06000020
    ldr r1, =0x11111111
    mov r2, #8
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b                     @ BG0 tile1 = solid idx1
    ldr r0, =0x06004000
    ldr r1, =0x00010001
    mov r2, #512
2:  str r1, [r0], #4
    subs r2, r2, #1
    bne 2b                     @ BG0 map = tile1
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r2, #8
3:  str r1, [r0], #4
    subs r2, r2, #1
    bne 3b                     @ OBJ tile0 = solid idx1
    ldr r1, =0x0800
    strh r1, [r12, #0x08]      @ BG0CNT screen base 8
    ldr r1, =0x0100
    strh r1, [r12, #0x4A]      @ WINOUT: out=0, objwin=BG0
    ldr r0, =0x07000000
    ldr r1, =0x0832
    strh r1, [r0]              @ y=50 mode2(window)
    ldr r1, =0x8032
    strh r1, [r0, #2]          @ x=50 size 32x32
    mov r1, #0
    strh r1, [r0, #4]
    ldr r1, =0x9140
    strh r1, [r12]             @ mode0 BG0 OBJ OBJwin 1D
forever:
    b forever
