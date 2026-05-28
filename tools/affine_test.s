@ Minimal GBA affine-BG test ROM (mode 2, BG2 rotated/scaled).
.arm
.section .text
.global _start
_start:
    b main
    @ pad to 0xC0 for header (filled by build script with a real header)
    .space 0xC0 - 4

main:
    ldr r0, =0x04000000        @ I/O base

    @ Build a palette at 0x05000000: entry0=black, 1..15 distinct colors.
    ldr r1, =0x05000000
    mov r2, #0
    strh r2, [r1]              @ color 0 = black (backdrop)
    ldr r2, =0x001F            @ red
    strh r2, [r1, #2]
    ldr r2, =0x03E0            @ green
    strh r2, [r1, #4]
    ldr r2, =0x7C00            @ blue
    strh r2, [r1, #6]
    ldr r2, =0x7FFF            @ white
    strh r2, [r1, #8]

    @ Tile data at 0x06000000 (charbase 0). 256-color tiles (mode2 affine = 8bpp).
    @ Tile 1 = 64 bytes; fill with a gradient of indices 1..4 in quadrants.
    ldr r1, =0x06000040        @ tile 1 (tile 0 left as 0/transparent-ish backdrop)
    mov r3, #0
fill_tile:
    @ index pattern: top-left=1, top-right=2, bottom-left=3, bottom-right=4
    @ compute row = r3/8, col within via loop; simpler: alternate 1/2 by byte
    and r4, r3, #1
    add r4, r4, #1             @ 1 or 2
    strb r4, [r1, r3]
    add r3, r3, #1
    cmp r3, #64
    blt fill_tile

    @ Affine map at screenbase block 8 = 0x06004000. Size 0 = 16x16 entries (1 byte each).
    ldr r1, =0x06004000
    mov r3, #0
    mov r4, #1                 @ all map entries point to tile 1
fill_map:
    strb r4, [r1, r3]
    add r3, r3, #1
    cmp r3, #256              @ 16x16
    blt fill_map

    @ BG2CNT (0x400000C): charbase 0, screenbase block 8, 256-color, size 0.
    mov r1, #0x800            @ screenbase block 8 (bits 8-12)
    strh r1, [r0, #0xC]

    @ Affine matrix: a ~26.5-degree rotation, scale 1. PA=PD=0xE0, PB=0x80, PC=-0x80.
    mov r1, #0xE0
    strh r1, [r0, #0x20]      @ BG2PA
    mov r1, #0x80
    strh r1, [r0, #0x22]      @ BG2PB
    ldr r1, =0xFF80           @ -0x80 (16-bit)
    strh r1, [r0, #0x24]      @ BG2PC
    mov r1, #0xE0
    strh r1, [r0, #0x26]      @ BG2PD
    @ reference point X=Y=0
    mov r1, #0
    str r1, [r0, #0x28]       @ BG2X (32-bit)
    str r1, [r0, #0x2C]       @ BG2Y

    @ DISPCNT = mode 2 | BG2 enable (0x402)
    mov r1, #0x400
    orr r1, r1, #2
    strh r1, [r0]

forever:
    b forever
