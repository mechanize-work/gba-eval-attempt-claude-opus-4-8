.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ color buffer in EWRAM: red, green, blue, white, yellow, cyan
    ldr r0, =0x02000000
    ldr r1, =0x001F
    strh r1, [r0]
    ldr r1, =0x03E0
    strh r1, [r0, #2]
    ldr r1, =0x7C00
    strh r1, [r0, #4]
    ldr r1, =0x7FFF
    strh r1, [r0, #6]
    ldr r1, =0x03FF
    strh r1, [r0, #8]
    ldr r1, =0x7FE0
    strh r1, [r0, #10]
    @ palette[1] initial = red
    ldr r0, =0x05000000
    ldr r1, =0x001F
    strh r1, [r0, #2]
    @ BG0 tile0 = idx1
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x0800
    strh r1, [r12, #8]
    @ VBlank DMA0: src=buffer dst=palette[1](0x05000002) count=1 ctrl=0x9240 (en,VBlank,repeat,dstfixed,16bit,srcinc)
    ldr r1, =0x02000000
    str r1, [r12, #0xB0]
    ldr r1, =0x05000002
    str r1, [r12, #0xB4]
    ldr r1, =0x92400001
    str r1, [r12, #0xB8]
    ldr r1, =0x0100
    strh r1, [r12]
forever:
    b forever
