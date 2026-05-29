.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x000A          @ palette[0] backdrop R10
    strh r1, [r0]
    ldr r1, =0x0014          @ palette[1] R20
    strh r1, [r0, #2]
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x0800          @ BG0CNT prio0 sb8
    strh r1, [r12, #8]
    @ BLDCNT: alpha(0x40) + BG0 1st(0x01) + BD 2nd(0x2000) = 0x2041
    ldr r1, =0x2041
    strh r1, [r12, #0x50]
    ldr r1, =0x0808          @ EVA8 EVB8
    strh r1, [r12, #0x52]
    ldr r1, =0x0100          @ mode0 BG0
    strh r1, [r12]
forever:
    b forever
