.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ EWRAM[0] = blue (0x7C00)
    ldr r0, =0x02000000
    ldr r1, =0x7C00
    str r1, [r0]
    @ BG tile 0 = index 1
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ palette[1] = red initially
    ldr r0, =0x05000002
    ldr r1, =0x001F
    strh r1, [r0]
    ldr r1, =0x0800
    strh r1, [r12, #8]        @ BG0CNT
    @ DMA0: src=EWRAM[0] (fixed=blue), dst=palette[1] (fixed), count=1, hblank, repeat
    ldr r1, =0x02000000
    str r1, [r12, #0xB0]
    ldr r1, =0x05000002
    str r1, [r12, #0xB4]
    ldr r1, =0xA3C00001       @ enable|hblank|repeat|dstfixed|srcfixed
    str r1, [r12, #0xB8]
    ldr r1, =0x0100
    strh r1, [r12]            @ DISPCNT BG0
forever:
    b forever
