.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ set a BG with red so we can confirm forced-blank overrides it
    ldr r0, =0x05000000
    ldr r1, =0x001F
    strh r1, [r0, #2]
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x0800
    strh r1, [r12, #8]
    @ DISPCNT: forced blank (bit7=0x80) + mode0 + BG0
    ldr r1, =0x0180
    strh r1, [r12]
forever:
    b forever
