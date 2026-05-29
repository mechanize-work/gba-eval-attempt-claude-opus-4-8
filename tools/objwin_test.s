.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ BG palette[1]=red, [2]=blue
    ldr r0, =0x05000000
    ldr r1, =0x001F
    strh r1, [r0, #2]
    ldr r1, =0x7C00
    strh r1, [r0, #4]
    @ BG tile 0 @0x06000000 = index1 (red), tile 1 @0x06000020 = index2 (blue)
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
    @ OBJ tile 0 @0x06010000 = index1 (sprite content; ignored for obj-window)
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r3, #8
3:  str r1, [r0], #4
    subs r3, r3, #1
    bne 3b
    @ BG0 map @0x06004000 (screen base 8) = tile 0 (red): already zeroed -> tile 0. good.
    @ BG1 map @0x06004800 (screen base 9) = tile 1 (blue)
    ldr r0, =0x06004800
    ldr r1, =0x00010001
    mov r3, #512
4:  str r1, [r0], #4
    subs r3, r3, #1
    bne 4b
    @ BG0CNT: screen base 8, prio 1
    ldr r1, =0x0801
    strh r1, [r12, #8]
    @ BG1CNT: screen base 9, prio 0
    ldr r1, =0x0900
    strh r1, [r12, #0xA]
    @ OBJ-window sprite OAM[0]: gfx mode 2 (0x0800), y=40, 16x16
    ldr r0, =0x07000000
    ldr r1, =0x0828            @ attr0: y=40, gfx mode 2, square
    strh r1, [r0]
    ldr r1, =0x8028            @ attr1: x=40, 32x32 (size2)
    strh r1, [r0, #2]
    mov r1, #0
    strh r1, [r0, #4]
    @ WINOUT: outside = BG1 (0x02); obj-window inside = BG0 (0x01<<8 = 0x100)
    ldr r1, =0x0102
    strh r1, [r12, #0x4A]
    @ DISPCNT: mode0 BG0 BG1 OBJ obj-window 1D
    ldr r1, =0x9740
    strh r1, [r12]
forever:
    b forever
