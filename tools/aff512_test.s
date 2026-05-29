.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ palette: 2=green, 3=blue
    ldr r1, =0x05000000
    ldr r2, =0x03E0
    strh r2, [r1, #4]
    ldr r2, =0x7C00
    strh r2, [r1, #6]
    @ 8bpp tile1 @ 0x06000040 = idx2(green), tile2 @ 0x06000080 = idx3(blue)
    ldr r1, =0x06000040
    ldr r2, =0x02020202
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #64
    blt 1b
    ldr r1, =0x06000080
    ldr r2, =0x03030303
    mov r3, #0
2:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #64
    blt 2b
    @ map @ 0x06004000 (block8), 64x64: col<32 -> tile1, else tile2
    ldr r1, =0x06004000
    mov r3, #0
    ldr r6, =4096
3:  and r4, r3, #63
    cmp r4, #32
    movlt r4, #1
    movge r4, #2
    strb r4, [r1, r3]
    add r3, r3, #1
    cmp r3, r6
    blt 3b
    @ BG2CNT: size2(0x8000, 512px), screenbase block8(0x0800), charbase0
    ldr r1, =0x8800
    strh r1, [r0, #0xC]
    @ matrix PA=PD=0x200 (2x zoom out), ref 0
    ldr r1, =0x200
    strh r1, [r0, #0x20]
    mov r1, #0
    strh r1, [r0, #0x22]
    strh r1, [r0, #0x24]
    ldr r1, =0x200
    strh r1, [r0, #0x26]
    mov r1, #0
    str r1, [r0, #0x28]
    str r1, [r0, #0x2C]
    ldr r1, =0x0402           @ DISPCNT mode2 | BG2
    strh r1, [r0]
forever:
    b forever
