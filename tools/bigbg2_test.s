.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000002
    ldr r1, =0x001F
    strh r1, [r0]
    ldr r1, =0x03E0
    strh r1, [r0, #2]
    ldr r0, =0x06000020
    ldr r1, =0x11111111
    mov r2, #8
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b
    ldr r1, =0x22222222
    mov r2, #8
2:  str r1, [r0], #4
    subs r2, r2, #1
    bne 2b
    ldr r0, =0x06004000        @ SB0+SB1 = tile1 (1024 words)
    ldr r1, =0x00010001
    mov r2, #1024
3:  str r1, [r0], #4
    subs r2, r2, #1
    bne 3b
    ldr r1, =0x00020002        @ SB2+SB3 = tile2
    mov r2, #1024
4:  str r1, [r0], #4
    subs r2, r2, #1
    bne 4b
    ldr r1, =0xC800            @ BG0CNT size3(512x512), screen base 8
    strh r1, [r12, #0x08]
    ldr r1, =128
    strh r1, [r12, #0x12]      @ BG0VOFS=128 (straddle SB0/SB2 vertical boundary)
    ldr r1, =0x0100
    strh r1, [r12]
forever:
    b forever
