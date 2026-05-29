.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x001F          @ backdrop red
    strh r1, [r0]
    @ fill mode3-style VRAM with blue (in case mode7 shows bitmap)
    ldr r0, =0x06000000
    ldr r1, =0x7C007C00
    ldr r3, =4800
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x0407          @ DISPCNT mode 7 + BG2
    strh r1, [r12]
forever:
    b forever
