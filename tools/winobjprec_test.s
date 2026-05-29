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
    bne 1b                     @ BG0 tile1
    ldr r0, =0x06004000
    ldr r1, =0x00010001
    mov r2, #512
2:  str r1, [r0], #4
    subs r2, r2, #1
    bne 2b                     @ BG0 map
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r2, #32
3:  str r1, [r0], #4
    subs r2, r2, #1
    bne 3b                     @ OBJ tiles 0-3 (16x16) filled
    ldr r1, =0x0800
    strh r1, [r12, #0x08]      @ BG0CNT screen base 8
    ldr r0, =0x07000000
    ldr r1, =0x0848            @ y=72, gfx_mode2 (objwin)
    strh r1, [r0]
    ldr r1, =0x4032            @ x=50, size 16x16
    strh r1, [r0, #2]
    mov r1, #0
    strh r1, [r0, #4]
    ldr r1, =0x003A
    strh r1, [r12, #0x40]      @ WIN0H x 0-58
    ldr r1, =0x00A0
    strh r1, [r12, #0x44]      @ WIN0V full
    mov r1, #0x01
    strh r1, [r12, #0x48]      @ WININ win0=BG0
    mov r1, #0
    strh r1, [r12, #0x4A]      @ WINOUT: objwin=0, outside=0
    ldr r1, =0xB140            @ mode0+BG0+OBJ+objwin+win0+1D
    strh r1, [r12]
forever:
    b forever
