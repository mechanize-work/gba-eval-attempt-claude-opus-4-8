.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x05000000
    ldr r2, =0x03E0           @ palette[1]=green
    strh r2, [r1, #2]
    ldr r2, =0x001F           @ palette[2]=red
    strh r2, [r1, #4]
    @ RED tile (index2) at VRAM 0x0000 (charbase0 tile0)
    ldr r1, =0x06000000
    ldr r2, =0x22222222
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 1b
    @ GREEN tile (index1) at VRAM 0x10000
    ldr r1, =0x06010000
    ldr r2, =0x11111111
    mov r3, #0
2:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 2b
    @ BG0 map @ 0x06001000 (block2): all tile 512
    ldr r1, =0x06001000
    ldr r4, =0x0200
    mov r3, #0
3:  strh r4, [r1, r3]
    add r3, r3, #2
    cmp r3, #2048
    blt 3b
    ldr r1, =0x020C           @ BG0CNT charbase3 + screenbase block2
    strh r1, [r0, #8]
    ldr r1, =0x0100
    strh r1, [r0]
forever:
    b forever
