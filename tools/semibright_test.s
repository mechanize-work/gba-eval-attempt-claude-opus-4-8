.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000202
    ldr r1, =0x4210
    strh r1, [r0]              @ OBJ pal[1] = gray (16,16,16)
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r2, #8
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b                     @ OBJ tile0 = idx1
    ldr r0, =0x07000000
    ldr r1, =0x0432
    strh r1, [r0]              @ y=50, gfx_mode1 (semi-transparent)
    ldr r1, =0x0032
    strh r1, [r0, #2]          @ x=50, 8x8
    mov r1, #0
    strh r1, [r0, #4]
    mov r1, #0x90
    strh r1, [r12, #0x50]      @ BLDCNT: mode2(brighten) + OBJ 1st target, NO 2nd target
    mov r1, #0x10
    strh r1, [r12, #0x54]      @ BLDY = 16 (full brighten)
    ldr r1, =0x1040
    strh r1, [r12]             @ DISPCNT OBJ on, 1D
forever:
    b forever
