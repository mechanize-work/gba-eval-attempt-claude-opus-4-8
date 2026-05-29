.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ palette[1]=R20 (0x0014), palette[2]=R10 (0x000A)
    ldr r0, =0x05000000
    ldr r1, =0x0014
    strh r1, [r0, #2]
    ldr r1, =0x000A
    strh r1, [r0, #4]
    @ tile0 = idx1, tile1 = idx2
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
    @ BG1 map @0x06004800 -> tile1
    ldr r0, =0x06004800
    ldr r1, =0x00010001
    mov r3, #512
3:  str r1, [r0], #4
    subs r3, r3, #1
    bne 3b
    @ BG0CNT prio0 sb8=0x0800, BG1CNT prio1 sb9=0x0901
    ldr r1, =0x0800
    strh r1, [r12, #8]
    ldr r1, =0x0901
    strh r1, [r12, #0xA]
    @ BLDCNT: alpha(0x40) + BG0 1st(0x01) + BG1 2nd(0x200) = 0x241
    ldr r1, =0x0241
    strh r1, [r12, #0x50]
    @ BLDALPHA: EVA=13, EVB=4 -> 0x040D
    ldr r1, =0x040D
    strh r1, [r12, #0x52]
    @ DISPCNT mode0 BG0+BG1
    ldr r1, =0x0300
    strh r1, [r12]
forever:
    b forever
