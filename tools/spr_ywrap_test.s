.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ OBJ palette[1] = green
    ldr r0, =0x05000202
    ldr r1, =0x03E0
    strh r1, [r0]
    @ OBJ tile 0..15 (32x32 = 16 tiles) filled with index 1
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r3, #128              @ 16 tiles * 8 words = 128 words
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ OAM[0]: y=240, 32x32, x=100
    ldr r0, =0x07000000
    ldr r1, =0x80F0          @ attr0: y=240(0xF0), shape sq(0), size bits in attr1; bit15? 0x8000=shape? 
    @ recompute: shape bits 14-15. square=00. y=0xF0. so attr0 = 0x00F0
    ldr r1, =0x00F0
    strh r1, [r0]
    ldr r1, =0x8064          @ attr1: x=100(0x64), size 2 (32x32) -> bits14-15=10=0x8000
    strh r1, [r0, #2]
    mov r1, #0
    strh r1, [r0, #4]        @ attr2: tile 0
    @ DISPCNT: OBJ on, 1D mapping
    ldr r1, =0x1040
    strh r1, [r12]
forever:
    b forever
