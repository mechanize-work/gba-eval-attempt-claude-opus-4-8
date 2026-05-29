@ 8bpp multi-tile sprite mapping: 16x16 256-color sprite at (16,16).
@ 8bpp tile = 2 slots (64 bytes). 1D pitch = tile_w*2; col step = 2 slots.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4

main:
    ldr r0, =0x04000000

    @ OBJ 256-palette @ 0x05000200: 1..6 distinct
    ldr r1, =0x05000200
    ldr r2, =0x001F
    strh r2, [r1, #2]
    ldr r2, =0x03E0
    strh r2, [r1, #4]
    ldr r2, =0x7C00
    strh r2, [r1, #6]
    ldr r2, =0x03FF
    strh r2, [r1, #8]
    ldr r2, =0x7FE0
    strh r2, [r1, #10]
    ldr r2, =0x7C1F
    strh r2, [r1, #12]

    @ 8bpp tiles (64 bytes each). tile0(slot0)@..0000=idx1, tile2(slot2)@..0040=idx2,
    @ tile4(slot4)@..0080=idx3, tile6(slot6)@..00C0=idx4 (1D bottom row),
    @ slot32@..0400=idx5, slot34@..0440=idx6 (2D bottom row)
    ldr r1, =0x06010000
    ldr r2, =0x01010101
    bl fill64
    ldr r1, =0x06010040
    ldr r2, =0x02020202
    bl fill64
    ldr r1, =0x06010080
    ldr r2, =0x03030303
    bl fill64
    ldr r1, =0x060100C0
    ldr r2, =0x04040404
    bl fill64
    ldr r1, =0x06010400
    ldr r2, =0x05050505
    bl fill64
    ldr r1, =0x06010440
    ldr r2, =0x06060606
    bl fill64

    @ OAM: 16x16 square 8bpp at (16,16), tile 0
    ldr r1, =0x07000000
    ldr r2, =0x2010       @ attr0 Y=16, color256(0x2000), square
    strh r2, [r1]
    ldr r2, =0x4010       @ attr1 X=16, size1
    strh r2, [r1, #2]
    mov r2, #0
    strh r2, [r1, #4]

    ldr r1, =0x1000       @ DISPCNT mode0|OBJ|1D (2D variant: 0x1000)
    strh r1, [r0]
forever:
    b forever

fill64:
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #64
    blt 1b
    bx lr
