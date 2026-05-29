.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x06000000
    ldr r1, =0x001F001F
    ldr r2, =10240
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b                     @ fill 160x128 bitmap red
    ldr r1, =0x0100
    strh r1, [r12, #0x20]      @ BG2PA = 1.0
    mov r1, #0
    strh r1, [r12, #0x22]      @ BG2PB = 0
    strh r1, [r12, #0x24]      @ BG2PC = 0
    ldr r1, =0x0100
    strh r1, [r12, #0x26]      @ BG2PD = 1.0
    mov r1, #0
    str r1, [r12, #0x28]       @ BG2X = 0
    str r1, [r12, #0x2C]       @ BG2Y = 0
    ldr r1, =0x0405
    strh r1, [r12]             @ mode5 + BG2
forever:
    b forever
