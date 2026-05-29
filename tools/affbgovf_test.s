.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ palette[0]=red(backdrop), [1]=green
    ldr r0, =0x05000000
    ldr r1, =0x001F
    strh r1, [r0]
    ldr r1, =0x03E0
    strh r1, [r0, #2]
    @ tile1 @ 0x06000040: 64 bytes of color 1 (8bpp)
    ldr r0, =0x06000040
    ldr r1, =0x01010101
    mov r3, #16
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ map @ 0x0600C000 (screen base 24): 256 bytes of tile 1 (16x16)
    ldr r0, =0x0600C000
    ldr r1, =0x01010101
    mov r3, #64
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    @ affine identity PA=PD=0x100
    ldr r1, =0x0100
    strh r1, [r12, #0x20]
    mov r1, #0
    strh r1, [r12, #0x22]
    strh r1, [r12, #0x24]
    ldr r1, =0x0100
    strh r1, [r12, #0x26]
    mov r1, #0
    str r1, [r12, #0x28]
    str r1, [r12, #0x2C]
    @ BG2CNT: screen base 24, size 0 (128x128), overflow=OVFBIT
    ldr r1, =0xBGCNT
    strh r1, [r12, #0xC]
    @ DISPCNT mode 2 + BG2
    ldr r1, =0x0402
    strh r1, [r12]
forever:
    b forever
