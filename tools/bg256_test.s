.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ palette[100] = yellow (0x03FF) at 0x05000000 + 200
    ldr r0, =0x050000C8
    ldr r1, =0x03FF
    strh r1, [r0]
    @ tile0 (8bpp) at 0x06000000: 64 bytes of idx 100 (0x64)
    ldr r0, =0x06000000
    ldr r1, =0x64646464
    mov r3, #16
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ BG0CNT: 256-color(0x80) + screen base 8(0x0800) + prio0 = 0x0880
    ldr r1, =0x0880
    strh r1, [r12, #8]
    @ DISPCNT mode0 BG0
    ldr r1, =0x0100
    strh r1, [r12]
forever:
    b forever
