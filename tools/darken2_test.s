.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x29CB          @ palette[1]: R11 G14 B10 (arbitrary)
    strh r1, [r0, #2]
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x0800
    strh r1, [r12, #8]
    ldr r1, =0x00C1
    strh r1, [r12, #0x50]
    mov r1, #11              @ EVY=11
    strh r1, [r12, #0x54]
    ldr r1, =0x0100
    strh r1, [r12]
forever:
    b forever
