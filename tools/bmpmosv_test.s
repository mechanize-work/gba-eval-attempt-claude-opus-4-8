.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ fill each row y with R = y & 0x1F (vertical gradient), col 120 only region
    ldr r0, =0x06000000
    mov r4, #0
rowloop:
    and r1, r4, #0x1F
    orr r1, r1, r1, lsl #16
    mov r3, #120          @ 240 px = 120 words
    add r5, r0, r4, lsl #1
    add r5, r5, r4, lsl #1   @ +y*480? need y*240*2. do via mul
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    add r4, r4, #1
    cmp r4, #160
    blt rowloop
    ldr r1, =0x0040
    strh r1, [r12, #0xC]
    ldr r1, =0x0070       @ MOSAIC v=8 (bits4-7=7)
    strh r1, [r12, #0x4C]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
