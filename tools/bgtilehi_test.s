.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ palette[1] = green
    ldr r1, =0x05000000
    ldr r2, =0x03E0
    strh r2, [r1, #2]
    @ put a green tile (index1) at VRAM 0x10000 (where charbase3+tile512 points)
    ldr r1, =0x06010000
    ldr r2, =0x11111111
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 1b
    @ BG0 map @ screenbase block2 (0x1000): all tile 512
    ldr r1, =0x06001000
    ldr r4, =0x0200           @ tile 512
    mov r3, #0
2:  strh r4, [r1, r3]
    add r3, r3, #2
    cmp r3, #2048
    blt 2b
    @ BG0CNT: charbase3(0x0C), screenbase block2(0x200), 4bpp
    ldr r1, =0x020C
    strh r1, [r0, #8]
    ldr r1, =0x0100           @ DISPCNT mode0 | BG0
    strh r1, [r0]
forever:
    b forever
