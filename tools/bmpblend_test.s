.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ backdrop palette[0] = red (2nd target)
    ldr r0, =0x05000000
    ldr r1, =0x001F
    strh r1, [r0]
    @ mode3 bitmap: fill VRAM with blue (0x7C00)
    ldr r0, =0x06000000
    ldr r1, =0x7C007C00
    ldr r3, =9600        @ 240*160/2 words... fill region
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ BLDCNT: alpha(1) + BG2 1st(0x04) + backdrop 2nd(0x2000)
    ldr r1, =0x2005
    strh r1, [r12, #0x50]
    @ BLDALPHA EVA=8 EVB=8
    ldr r1, =0x0808
    strh r1, [r12, #0x52]
    @ DISPCNT mode3 + BG2
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
