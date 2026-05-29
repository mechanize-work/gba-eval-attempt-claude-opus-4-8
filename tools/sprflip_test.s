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
    ldr r0, =0x06010000        @ OBJ tile0 corner marker
    mov r1, #1
    str r1, [r0]
    mov r1, #0
    mov r2, #7
1:  str r1, [r0, #4]
    add r0, r0, #4
    subs r2, r2, #1
    bne 1b
    ldr r0, =0x07000000
    ldr r1, =0x0032
    strh r1, [r0]              @ spr0 y=50
    ldr r1, =0x1032
    strh r1, [r0, #2]          @ spr0 x=50 H-flip(0x1000)
    mov r1, #0
    strh r1, [r0, #4]
    ldr r1, =0x003C
    strh r1, [r0, #8]          @ spr1 y=60
    ldr r1, =0x2032
    strh r1, [r0, #10]         @ spr1 x=50 V-flip(0x2000)
    mov r1, #0
    strh r1, [r0, #12]
    ldr r1, =0x1040
    strh r1, [r12]
forever:
    b forever
