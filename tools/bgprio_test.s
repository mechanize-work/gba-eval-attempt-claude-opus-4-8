.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000002
    ldr r1, =0x001F
    strh r1, [r0]              @ pal[1]=red
    ldr r1, =0x03E0
    strh r1, [r0, #2]          @ pal[2]=green
    ldr r0, =0x06000020
    ldr r1, =0x11111111
    mov r2, #8
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b
    ldr r1, =0x22222222
    mov r2, #8
2:  str r1, [r0], #4
    subs r2, r2, #1
    bne 2b
    ldr r0, =0x06004000        @ SB8 = tile1 (BG0)
    ldr r1, =0x00010001
    mov r2, #512
3:  str r1, [r0], #4
    subs r2, r2, #1
    bne 3b
    ldr r1, =0x00020002        @ SB9 = tile2 (BG1)
    mov r2, #512
4:  str r1, [r0], #4
    subs r2, r2, #1
    bne 4b
    ldr r1, =0x0800            @ BG0CNT screen base 8, priority 0
    strh r1, [r12, #0x08]
    ldr r1, =0x0900            @ BG1CNT screen base 9, priority 0
    strh r1, [r12, #0x0A]
    ldr r1, =0x0300            @ DISPCNT mode0 + BG0 + BG1
    strh r1, [r12]
forever:
    b forever
