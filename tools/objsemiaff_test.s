@ Semi-transparent AFFINE sprite: affine bit + gfx mode1 + identity matrix.
@ Tests the affine-sample path combined with OBJ alpha-blend. Should match
@ a plain semi sprite (identity) blended 8/8 over BG0.
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
    @ BG tile0 + OBJ tile0 filled index1
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

    @ OAM[0]: affine (bit8) + semi (bit10) sprite
    ldr r0, =0x07000000
    ldr r1, =0x0540           @ attr0: y=64, affine(0x100), semi(0x400)
    strh r1, [r0]
    ldr r1, =0x4040           @ attr1: x=64, matrix group0, size1 (16x16)
    strh r1, [r0, #2]
    mov r1, #0
    strh r1, [r0, #4]
    @ identity affine matrix (group0): PA@+6 PB@+E PC@+16 PD@+1E
    ldr r1, =0x0100
    strh r1, [r0, #0x06]      @ PA
    mov r1, #0
    strh r1, [r0, #0x0E]      @ PB
    strh r1, [r0, #0x16]      @ PC
    ldr r1, =0x0100
    strh r1, [r0, #0x1E]      @ PD

    ldr r1, =0x0150           @ BLDCNT OBJ-t1 + BG0-t2 + alpha
    strh r1, [r12, #0x50]
    ldr r1, =0x0808           @ BLDALPHA 8/8
    strh r1, [r12, #0x52]
    ldr r1, =0x1140           @ DISPCNT mode0|BG0|OBJ|1D
    strh r1, [r12]
forever:
    b forever
