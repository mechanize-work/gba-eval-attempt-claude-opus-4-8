.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ BG palette[1] = red
    ldr r0, =0x05000000
    ldr r1, =0x001F
    strh r1, [r0, #2]
    @ affine tile 0 @0x06000000: 8bpp 8x8 = 64 bytes of index 1
    ldr r0, =0x06000000
    ldr r1, =0x01010101
    mov r3, #16
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ affine map @0x06004000 (screen base 8): 16x16 = 256 bytes of tile 0 (already 0). good.
    @ BG2CNT: wrap(0x2000) | screen base 8 (0x800) | size0(128x128)
    ldr r1, =0x2800
    strh r1, [r12, #0xC]      @ BG2CNT @ 0x400000C
    @ affine params: PA=0x100, PB=0, PC=0, PD=0x100, ref=0
    ldr r1, =0x0100
    strh r1, [r12, #0x20]     @ BG2PA
    mov r1, #0
    strh r1, [r12, #0x22]     @ BG2PB
    strh r1, [r12, #0x24]     @ BG2PC
    ldr r1, =0x0100
    strh r1, [r12, #0x26]     @ BG2PD
    mov r1, #0
    str r1, [r12, #0x28]      @ BG2X = 0
    str r1, [r12, #0x2C]      @ BG2Y = 0
    @ DISPCNT mode 2, BG2
    ldr r1, =0x0402
    strh r1, [r12]
forever:
    b forever
