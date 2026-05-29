.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ BG palette[1] = red (0x001F)
    ldr r0, =0x05000000
    ldr r1, =0x001F
    strh r1, [r0, #2]
    @ OBJ palette[1] = green (0x03E0)
    ldr r1, =0x03E0
    ldr r2, =0x05000202
    strh r1, [r2]
    @ BG tile 0 @ 0x06000000 filled with index 1
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ OBJ tile 0 @ 0x06010000 filled with index 1
    ldr r0, =0x06010000
    mov r3, #8
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    @ BG0CNT: screen base block 8 (map @ 0x06004000)
    ldr r1, =0x0800
    strh r1, [r12, #8]
    @ OAM[0]
    ldr r0, =0x07000000
    ldr r1, =0x0428            @ attr0: y=40, semi-transparent (gfx mode 1)
    strh r1, [r0]
    ldr r1, =0x0028            @ attr1: x=40, 8x8
    strh r1, [r0, #2]
    mov r1, #0                 @ attr2: tile 0, prio 0
    strh r1, [r0, #4]
    @ BLDCNT: OBJ 1st(0x10)+BG0 2nd(0x100)+alpha(0x40); BLDALPHA eva=8 evb=8
    ldr r1, =0x0150
    strh r1, [r12, #0x50]
    ldr r1, =0x0808
    strh r1, [r12, #0x52]
    @ DISPCNT: mode0, BG0, OBJ, 1D
    ldr r1, =0x1140
    strh r1, [r12]
forever:
    b forever
