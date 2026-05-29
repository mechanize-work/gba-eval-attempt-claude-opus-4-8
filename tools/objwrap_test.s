.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    @ OBJ palette entry 1 = green
    ldr r2, =0x05000200
    ldr r1, =0x03E0
    strh r1, [r2, #2]
    @ fill OBJ tiles (0x06010000) tiles 0..15 with index 1 (0x1111 per halfword)
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r3, #0
    ldr r4, =128            @ 16 tiles * 8 words
ft:
    str r1, [r0], #4
    add r3, r3, #1
    cmp r3, r4
    blt ft
    @ OAM entry0: 32x32 square sprite at X=500 (wraps), Y=80
    ldr r2, =0x07000000
    ldr r1, =0x0050        @ attr0: Y=80, square
    strh r1, [r2]
    ldr r1, =0x81F4        @ attr1: size2(0x8000) | X=500(0x1F4)
    strh r1, [r2, #2]
    mov r1, #0             @ attr2: tile0
    strh r1, [r2, #4]
    @ backdrop red
    ldr r2, =0x05000000
    ldr r1, =0x001F
    strh r1, [r2]
    @ DISPCNT = mode0 + OBJ(0x1000) + 1D map(0x40)
    ldr r2, =0x04000000
    ldr r1, =0x1040
    strh r1, [r2]
forever:
    b forever
    .ltorg
