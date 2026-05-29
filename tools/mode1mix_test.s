@ Mode 1 test: BG0 text (red, left 15 cols, prio 0) over BG2 affine (green, identity, prio 1).
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4

main:
    ldr r0, =0x04000000        @ I/O base

    @ Palette: 0=black, 1=red, 2=green
    ldr r1, =0x05000000
    mov r2, #0
    strh r2, [r1]
    ldr r2, =0x001F
    strh r2, [r1, #2]
    ldr r2, =0x03E0
    strh r2, [r1, #4]

    @ BG0 text 4bpp tile 1 at charbase 0 (0x06000000), tile 1 @ +0x20: all pixels index 1 (red)
    ldr r1, =0x06000020
    ldr r2, =0x11111111
    mov r3, #0
bg0tile:
    str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt bg0tile

    @ BG0 map at screenbase block 8 (0x06004000): cols 0-14 -> tile1, else tile0
    ldr r1, =0x06004000
    mov r5, #0                 @ row
b0row:
    mov r6, #0                 @ col
b0col:
    mov r7, r5, lsl #6         @ row*64
    add r7, r7, r6, lsl #1     @ + col*2
    cmp r6, #15
    movlt r4, #1
    movge r4, #0
    strh r4, [r1, r7]
    add r6, r6, #1
    cmp r6, #32
    blt b0col
    add r5, r5, #1
    cmp r5, #32
    blt b0row

    @ BG2 affine 8bpp tile 1 at charbase 2 (0x06008000), tile1 @ +0x40: index 2 (green)
    ldr r1, =0x06008040
    ldr r2, =0x02020202
    mov r3, #0
b2tile:
    str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #64
    blt b2tile

    @ BG2 affine map at screenbase block 20 (0x0600A000): 16x16 all tile 1
    ldr r1, =0x0600A000
    mov r4, #1
    mov r3, #0
b2map:
    strb r4, [r1, r3]
    add r3, r3, #1
    cmp r3, #256
    blt b2map

    @ BG0CNT (0x08): screenbase block8 (0x0800), charbase0, prio 0
    ldr r1, =0x0800
    strh r1, [r0, #8]

    @ BG2CNT (0x0C): screenbase block20 (0x1400), charbase2 (0x08), prio 1
    ldr r1, =0x1409
    strh r1, [r0, #0xC]

    @ BG2 affine identity matrix
    mov r1, #0x100
    strh r1, [r0, #0x20]       @ PA
    mov r1, #0
    strh r1, [r0, #0x22]       @ PB
    strh r1, [r0, #0x24]       @ PC
    mov r1, #0x100
    strh r1, [r0, #0x26]       @ PD
    mov r1, #0
    str r1, [r0, #0x28]        @ X
    str r1, [r0, #0x2C]        @ Y

    @ DISPCNT = mode1 | BG0 | BG2 = 0x501
    ldr r1, =0x0501
    strh r1, [r0]

forever:
    b forever
