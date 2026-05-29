.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ BG palette[1]=blue, OBJ palette[1]=red
    ldr r0, =0x05000000
    ldr r1, =0x7C00
    strh r1, [r0, #2]
    ldr r1, =0x001F
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
    @ OAM[0]: objwin definer (gfx mode2) at (40,40) 16x16
    ldr r0, =0x07000000
    ldr r1, =0x0828           @ y=40, gfx2(0x800)
    strh r1, [r0]
    ldr r1, =0x4028           @ x=40, size1
    strh r1, [r0, #2]
    mov r1, #0
    strh r1, [r0, #4]
    @ OAM[1]: semi-OBJ (gfx mode1, red) at (44,44) 8x8
    ldr r1, =0x042C           @ y=44, gfx1(0x400)
    strh r1, [r0, #8]
    ldr r1, =0x002C           @ x=44, 8x8
    strh r1, [r0, #10]
    mov r1, #0
    strh r1, [r0, #12]
    @ WINOUT: outside=all+fx(0x3F), objwin(bits8-13)=BG0(bit8)+OBJ(bit12), NO fx(bit13)
    ldr r1, =0x113F
    strh r1, [r12, #0x4A]
    @ BLDCNT alpha+OBJ t1+BG0 t2 ; BLDALPHA 8/8
    ldr r1, =0x0150
    strh r1, [r12, #0x50]
    ldr r1, =0x0808
    strh r1, [r12, #0x52]
    @ DISPCNT mode0|BG0|OBJ|OBJwin(0x8000)|1D(0x40)
    ldr r1, =0x9140
    strh r1, [r12]
forever:
    b forever
