.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r6, =0x06000000
    ldrh r2, [r12, #0x00]      @ DISPCNT (default 0x80)
    strh r2, [r6]
    ldrh r2, [r12, #0x02]      @ GREENSWAP
    strh r2, [r6, #2]
    ldrh r2, [r12, #0x08]      @ BG0CNT
    strh r2, [r6, #4]
    ldr r10, =0x04000204
    ldrh r2, [r10]             @ WAITCNT
    strh r2, [r6, #6]
    ldr r10, =0x04000130
    ldrh r2, [r10]             @ KEYINPUT
    strh r2, [r6, #8]
    ldr r10, =0x04000088
    ldrh r2, [r10]             @ SOUNDBIAS
    strh r2, [r6, #10]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
