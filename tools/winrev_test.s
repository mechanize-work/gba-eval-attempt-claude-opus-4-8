.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    @ BG2 affine identity (mode3 uses BG2 affine regs)
    ldr r2, =0x04000020
    ldr r1, =0x0100
    strh r1, [r2]
    mov r1, #0
    strh r1, [r2, #2]
    strh r1, [r2, #4]
    ldr r1, =0x0100
    strh r1, [r2, #6]
    ldr r2, =0x04000028
    mov r1, #0
    str r1, [r2]
    str r1, [r2, #4]
    @ fill mode3 BG2 buffer green
    ldr r0, =0x06000000
    ldr r1, =0x03E0
    ldr r4, =38400
    mov r3, #0
fill:
    strh r1, [r0], #2
    add r3, r3, #1
    cmp r3, r4
    blt fill
    @ backdrop red
    ldr r2, =0x05000000
    ldr r1, =0x001F
    strh r1, [r2]
    @ WIN0H: X1=200, X2=50  (X1>X2 reversed)
    ldr r2, =0x04000040
    ldr r1, =0xC832
    strh r1, [r2]
    ldr r1, =0x00A0
    strh r1, [r2, #4]        @ WIN0V = 0..160
    @ WININ = BG2 inside (bit2); WINOUT = 0
    ldr r2, =0x04000048
    mov r1, #0x04
    strh r1, [r2]
    mov r1, #0
    strh r1, [r2, #2]
    @ DISPCNT = mode3 + BG2 + WIN0
    ldr r2, =0x04000000
    ldr r1, =0x2403
    strh r1, [r2]
forever:
    b forever
    .ltorg
