.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000202
    ldr r1, =0x001F
    strh r1, [r0]              @ OBJ pal[1]=red
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r2, #32
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b                     @ OBJ tiles 0-3 = red (16x16)
    ldr r0, =0x07000000
    ldr r1, =0x0050
    strh r1, [r0]              @ y=80
    ldr r1, =0x41F4
    strh r1, [r0, #2]          @ x=500(-12), size 16x16
    mov r1, #0
    strh r1, [r0, #4]
    ldr r1, =0x1040
    strh r1, [r12]
forever:
    b forever
