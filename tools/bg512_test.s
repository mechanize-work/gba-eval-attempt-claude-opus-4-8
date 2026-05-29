.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x001F          @ pal[1] red
    strh r1, [r0, #2]
    ldr r1, =0x7C00          @ pal[2] blue
    strh r1, [r0, #4]
    @ tile0 red (idx1), tile1 blue (idx2)
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x22222222
    mov r3, #8
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    @ block0 (sb8, 0x06004000) = tile0; block1 (sb9, 0x06004800) = tile1
    ldr r0, =0x06004000
    ldr r1, =0x00000000
    mov r3, #512
3:  str r1, [r0], #4
    subs r3, r3, #1
    bne 3b
    ldr r0, =0x06004800
    ldr r1, =0x00010001
    mov r3, #512
4:  str r1, [r0], #4
    subs r3, r3, #1
    bne 4b
    @ BG0CNT: size1(0x4000) + sb8(0x0800) = 0x4800
    ldr r1, =0x4800
    strh r1, [r12, #8]
    @ bghofs = 250
    ldr r1, =250
    strh r1, [r12, #0x10]
    ldr r1, =0x0100
    strh r1, [r12]
forever:
    b forever
