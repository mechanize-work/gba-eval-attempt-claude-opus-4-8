.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ palette 1=red 2=green 3=blue 4=white
    ldr r1, =0x05000000
    ldr r2, =0x001F
    strh r2, [r1, #2]
    ldr r2, =0x03E0
    strh r2, [r1, #4]
    ldr r2, =0x7C00
    strh r2, [r1, #6]
    ldr r2, =0x7FFF
    strh r2, [r1, #8]
    @ tiles 1-4 (4bpp) each solid index 1-4
    ldr r1, =0x06000020
    ldr r2, =0x11111111
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 1b
    ldr r1, =0x06000040
    ldr r2, =0x22222222
    mov r3, #0
2:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 2b
    ldr r1, =0x06000060
    ldr r2, =0x33333333
    mov r3, #0
3:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 3b
    ldr r1, =0x06000080
    ldr r2, =0x44444444
    mov r3, #0
4:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 4b
    @ map @ 0x06004000: quadrant N (0x800 each) -> tile N+1
    ldr r1, =0x06004000
    mov r3, #0
    ldr r6, =0x2000
5:  mov r4, r3, lsr #11
    add r4, r4, #1
    strh r4, [r1, r3]
    add r3, r3, #2
    cmp r3, r6
    blt 5b
    @ BG0CNT size3(0xC000) + sb8(0x0800)
    ldr r1, =0xC800
    strh r1, [r0, #8]
    mov r1, #200
    strh r1, [r0, #0x10]       @ HOFS=200
    mov r1, #100
    strh r1, [r0, #0x12]       @ VOFS=100
    ldr r1, =0x0100
    strh r1, [r0]
forever:
    b forever
