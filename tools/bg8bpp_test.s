.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r1, =0x05000000
    ldr r2, =0x001F
    strh r2, [r1]
    ldr r2, =0x03E0
    strh r2, [r1, #2]         @ palette idx1 green
    @ tile1 8bpp at 0x06000040 (char base0, tile1 = +64)
    ldr r0, =0x06000040
    ldr r1, =0x01010101
    mov r3, #0
tf:
    str r1, [r0], #4
    add r3, r3, #1
    cmp r3, #16
    blt tf
    @ map at screen base1 = 0x06000800: entries = tile 0x0001
    ldr r0, =0x06000800
    ldr r1, =0x00010001
    mov r3, #0
mf:
    str r1, [r0], #4
    add r3, r3, #1
    cmp r3, #512
    blt mf
    @ BG0CNT = 256color(0x80) | screen base1(0x0100)
    ldr r2, =0x04000008
    ldr r1, =0x0180
    strh r1, [r2]
    ldr r2, =0x04000000
    ldr r1, =0x0100          @ mode0 + BG0
    strh r1, [r2]
forever:
    b forever
    .ltorg
