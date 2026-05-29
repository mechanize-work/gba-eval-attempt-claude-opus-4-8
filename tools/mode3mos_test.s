.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
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
    @ fill mode3 bitmap: color = (x&0x1F) | ((y&0x1F)<<5)
    ldr r0, =0x06000000
    mov r5, #0
yl:
    mov r6, #0
xl:
    and r1, r6, #0x1F
    and r7, r5, #0x1F
    orr r1, r1, r7, lsl #5
    strh r1, [r0], #2
    add r6, r6, #1
    cmp r6, #240
    blt xl
    add r5, r5, #1
    cmp r5, #160
    blt yl
    @ MOSAIC = bg 4x4 (val 3 each): 0x33
    ldr r2, =0x0400004C
    ldr r1, =0x33
    strh r1, [r2]
    @ BG2CNT mosaic bit (0x40)
    ldr r2, =0x0400000C
    ldr r1, =0x40
    strh r1, [r2]
    @ DISPCNT = mode3 + BG2
    ldr r2, =0x04000000
    ldr r1, =0x0403
    strh r1, [r2]
forever:
    b forever
    .ltorg
