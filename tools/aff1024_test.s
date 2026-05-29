.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x05000000
    ldr r2, =0x03E0           @ palette[2]=green
    strh r2, [r1, #4]
    @ 8bpp tile1 = green
    ldr r1, =0x06000040
    ldr r2, =0x02020202
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #64
    blt 1b
    @ map @ 0x06004000, 128x128 = 16384 bytes, all tile1
    ldr r1, =0x06004000
    ldr r2, =0x01010101
    mov r3, #0
    ldr r6, =16384
2:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, r6
    blt 2b
    @ BG2CNT size3(0xC000,1024px), screenbase block8, charbase0, NO wrap
    ldr r1, =0xC800
    strh r1, [r0, #0xC]
    @ PA=PD=0x400 (4x zoom out)
    ldr r1, =0x400
    strh r1, [r0, #0x20]
    mov r1, #0
    strh r1, [r0, #0x22]
    strh r1, [r0, #0x24]
    ldr r1, =0x400
    strh r1, [r0, #0x26]
    mov r1, #0
    str r1, [r0, #0x28]
    str r1, [r0, #0x2C]
    ldr r1, =0x0402
    strh r1, [r0]
forever:
    b forever
