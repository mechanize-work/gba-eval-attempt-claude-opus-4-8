.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
.align 2
affsrc:
    .hword 0x0100, 0x0100
    .hword 0x2000
    .hword 0x0000
    .align 2
main:
    ldr r0, =affsrc
    ldr r1, =0x02000000
    mov r2, #1
    mov r3, #2
    swi #0x0F0000              @ ObjAffineSet
    @ copy matrix (PA,PB,PC,PD at +0,+4,+8,+12) to mode3 framebuffer pixels 0-3
    ldr r1, =0x02000000
    ldr r6, =0x06000000
    ldrh r2, [r1]
    strh r2, [r6]
    ldrh r2, [r1, #4]
    strh r2, [r6, #2]
    ldrh r2, [r1, #8]
    strh r2, [r6, #4]
    ldrh r2, [r1, #12]
    strh r2, [r6, #6]
    @ DISPCNT mode 3, BG2 on
    ldr r0, =0x04000000
    ldr r1, =0x0403
    strh r1, [r0]
forever:
    b forever
