.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ palette [1]=red [2]=blue [3]=green
    ldr r0, =0x05000000
    ldr r1, =0x001F
    strh r1, [r0, #2]
    ldr r1, =0x7C00
    strh r1, [r0, #4]
    ldr r1, =0x03E0
    strh r1, [r0, #6]
    @ tile0=idx1, tile1=idx2, tile2=idx3
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x22222222
    mov r3, #8
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    ldr r1, =0x33333333
    mov r3, #8
3:  str r1, [r0], #4
    subs r3, r3, #1
    bne 3b
    @ BG1 map @0x06004800 = tile1
    ldr r0, =0x06004800
    ldr r1, =0x00010001
    mov r3, #512
4:  str r1, [r0], #4
    subs r3, r3, #1
    bne 4b
    @ BG2 map @0x06005000 = tile2
    ldr r0, =0x06005000
    ldr r1, =0x00020002
    mov r3, #512
5:  str r1, [r0], #4
    subs r3, r3, #1
    bne 5b
    @ BGxCNT: BG0 sb8 prio1=0x0801, BG1 sb9 prio0=0x0900, BG2 sb10 prio2=0x0A02
    ldr r1, =0x0801
    strh r1, [r12, #8]
    ldr r1, =0x0900
    strh r1, [r12, #0xA]
    ldr r1, =0x0A02
    strh r1, [r12, #0xC]
    @ WIN0H x0-160=0x00A0, WIN1H x80-240=0x50F0
    ldr r1, =0x00A0
    strh r1, [r12, #0x40]
    ldr r1, =0x50F0
    strh r1, [r12, #0x42]
    @ WIN0V y0-100, WIN1V y0-100 = 0x0064
    ldr r1, =0x0064
    strh r1, [r12, #0x44]
    strh r1, [r12, #0x46]
    @ WININ: WIN0=BG0(0x01), WIN1=BG1(0x02<<8)=0x0201
    ldr r1, =0x0201
    strh r1, [r12, #0x48]
    @ WINOUT: BG2(0x04)
    ldr r1, =0x0004
    strh r1, [r12, #0x4A]
    @ DISPCNT mode0 BG0 BG1 BG2 WIN0 WIN1
    ldr r1, =0x6700
    strh r1, [r12]
forever:
    b forever
