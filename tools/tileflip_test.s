.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r1, =0x05000000
    ldr r2, =0x03E0
    strh r2, [r1, #2]        @ idx1 green
    ldr r2, =0x7C00
    strh r2, [r1, #4]        @ idx2 blue
    @ tile1 4bpp at 0x06000020: (0,0)=idx1, rest idx2
    ldr r0, =0x06000020
    ldr r1, =0x22222221
    str r1, [r0], #4
    ldr r1, =0x22222222
    mov r3, #0
tr:
    str r1, [r0], #4
    add r3, r3, #1
    cmp r3, #7
    blt tr
    @ map at 0x06000800: tile1 normal, Hflip, Vflip, HVflip
    ldr r0, =0x06000800
    ldr r1, =0x0001
    strh r1, [r0]
    ldr r1, =0x0401
    strh r1, [r0, #2]
    ldr r1, =0x0801
    strh r1, [r0, #4]
    ldr r1, =0x0C01
    strh r1, [r0, #6]
    ldr r2, =0x04000008
    ldr r1, =0x0100          @ BG0CNT screen base1, 4bpp
    strh r1, [r2]
    ldr r2, =0x04000000
    ldr r1, =0x0100
    strh r1, [r2]
forever:
    b forever
    .ltorg
