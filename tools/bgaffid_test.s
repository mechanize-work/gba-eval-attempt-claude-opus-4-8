.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r0, #0
    strh r0, [r12]            @ DISPCNT=0 FIRST
    ldr r1, =0x05000000
    ldr r2, =0x001F           @ palette[0]=red MARKER
    strh r2, [r1]
    @ BgAffineSrc @ 0x02000000: centerX(s32)@0, centerY@4, dispX(s16)@8, dispY@A, scaleX@C, scaleY@E, angle@10
    ldr r1, =0x02000000
    mov r2, #0
    str r2, [r1, #0]          @ centerX = 0
    str r2, [r1, #4]          @ centerY = 0
    strh r2, [r1, #8]         @ dispX = 0
    strh r2, [r1, #0xA]       @ dispY = 0
    ldr r2, =0x100
    strh r2, [r1, #0xC]       @ scaleX
    strh r2, [r1, #0xE]       @ scaleY
    mov r2, #0
    strh r2, [r1, #0x10]      @ angle = 0
    @ BgAffineSet: r0=src, r1=dest, r2=count
    ldr r0, =0x02000000
    ldr r1, =0x02000020
    mov r2, #1
    swi 0x0E0000
    @ read PA (dest[0]) and StartX low halfword (dest+8)
    ldr r1, =0x02000020
    ldrh r3, [r1, #0]         @ PA -> 0xFF
    ldrh r4, [r1, #8]         @ StartX low -> 0
    eor r3, r3, r4
    ldr r1, =0x7FFF
    and r3, r3, r1
    ldr r1, =0x05000000
    strh r3, [r1]
forever:
    b forever
