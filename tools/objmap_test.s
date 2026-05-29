@ Multi-tile sprite mapping test: 16x16 (2x2 tiles) 4bpp sprite at (16,16).
@ Tile slots colored distinctly so 1D vs 2D arrangement is visible.
@ DISPCNT bit6 (0x40) toggles 1D(set)/2D(clear) -- patched per build.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4

main:
    ldr r0, =0x04000000

    @ OBJ palette @ 0x05000200: 1=red 2=green 3=blue 4=yellow 5=cyan 6=magenta
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

    @ OBJ tiles @ 0x06010000, 4bpp (32 bytes each). Fill slots with a uniform index.
    @ slot0=0x11(red) slot1=0x22 slot2=0x33 slot3=0x44 slot32=0x55 slot33=0x66
    ldr r1, =0x06010000
    ldr r2, =0x11111111
    bl fillslot          @ slot0
    ldr r1, =0x06010020
    ldr r2, =0x22222222
    bl fillslot          @ slot1
    ldr r1, =0x06010040
    ldr r2, =0x33333333
    bl fillslot          @ slot2
    ldr r1, =0x06010060
    ldr r2, =0x44444444
    bl fillslot          @ slot3
    ldr r1, =0x06010400
    ldr r2, =0x55555555
    bl fillslot          @ slot32
    ldr r1, =0x06010420
    ldr r2, =0x66666666
    bl fillslot          @ slot33

    @ OAM @ 0x07000000: 16x16 square sprite at (16,16), tile 0, prio 0
    ldr r1, =0x07000000
    mov r2, #16           @ attr0: Y=16, square, 4bpp, normal
    strh r2, [r1]
    ldr r2, =0x4010       @ attr1: X=16, size=1 (16x16)
    strh r2, [r1, #2]
    mov r2, #0            @ attr2: tile 0
    strh r2, [r1, #4]

    @ DISPCNT = mode0 | OBJ(0x1000) | MAPBIT
    ldr r1, =0x1040       @ MAPBIT: 0x40=1D ; 2D variant uses 0x1000
    strh r1, [r0]
forever:
    b forever

fillslot:
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 1b
    bx lr
