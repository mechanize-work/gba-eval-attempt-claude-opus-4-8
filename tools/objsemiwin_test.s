@ Semi-transparent OBJ inside WIN0 where color-effects are DISABLED (WININ bit5=0).
@ Tests whether the window's effect-enable bit gates semi-OBJ blending.
@ If gated: opaque green sprite. If not gated: green blended 8/8 with red BG -> olive.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x001F           @ BG palette[1] red
    strh r1, [r0, #2]
    ldr r1, =0x03E0           @ OBJ palette[1] green
    ldr r2, =0x05000202
    strh r1, [r2]
    @ BG tile0 + OBJ tile0 = index1
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r0, =0x06010000
    mov r3, #8
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    ldr r1, =0x0800
    strh r1, [r12, #8]        @ BG0CNT screenbase block8
    @ OAM[0]: 8x8 semi-transparent sprite at (40,40)
    ldr r0, =0x07000000
    ldr r1, =0x0428           @ attr0 y=40, semi(0x400)
    strh r1, [r0]
    ldr r1, =0x0028           @ attr1 x=40, 8x8
    strh r1, [r0, #2]
    mov r1, #0
    strh r1, [r0, #4]
    @ WIN0 covers whole screen; effects DISABLED inside (WININ bit5 clear)
    ldr r1, =0x00F0
    strh r1, [r12, #0x40]      @ WIN0H = 0..240
    ldr r1, =0x00A0
    strh r1, [r12, #0x44]      @ WIN0V = 0..160
    ldr r1, =0x0011           @ WININ: WIN0 = BG0(bit0)+OBJ(bit4), NO effects(bit5)
    strh r1, [r12, #0x48]
    ldr r1, =0x003F           @ WINOUT: all + effects (irrelevant, sprite inside WIN0)
    strh r1, [r12, #0x4A]
    @ BLDCNT alpha + OBJ t1 + BG0 t2 ; BLDALPHA 8/8
    ldr r1, =0x0150
    strh r1, [r12, #0x50]
    ldr r1, =0x0808
    strh r1, [r12, #0x52]
    @ DISPCNT mode0 | BG0 | OBJ | 1D | WIN0(0x2000)
    ldr r1, =0x3140
    strh r1, [r12]
forever:
    b forever
