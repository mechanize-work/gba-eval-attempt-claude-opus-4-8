.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    @ BG2 affine identity
    ldr r2, =0x04000020
    ldr r1, =0x0100
    strh r1, [r2]            @ PA=0x100
    mov r1, #0
    strh r1, [r2, #2]        @ PB=0
    strh r1, [r2, #4]        @ PC=0
    ldr r1, =0x0100
    strh r1, [r2, #6]        @ PD=0x100
    ldr r2, =0x04000028
    mov r1, #0
    str r1, [r2]            @ BG2X=0
    str r1, [r2, #4]        @ BG2Y=0
    @ backdrop red (shows outside 160x128)
    ldr r2, =0x05000000
    ldr r1, =0x001F
    strh r1, [r2]
    @ fill frame0 buffer (0x06000000) 160x128 with index-gradient
    ldr r0, =0x06000000
    mov r3, #0
    ldr r4, =20480
    ldr r5, =0x7FFF
fill:
    and r1, r3, r5
    strh r1, [r0], #2
    add r3, r3, #1
    cmp r3, r4
    blt fill
    @ DISPCNT = mode5 (5) + BG2 (bit10=0x400)
    ldr r2, =0x04000000
    ldr r1, =0x0405
    strh r1, [r2]
forever:
    b forever
    .ltorg
