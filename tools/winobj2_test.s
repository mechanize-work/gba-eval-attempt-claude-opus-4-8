.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000200
    ldr r1, =0x001F          @ OBJ pal[1] red
    strh r1, [r0, #2]
    ldr r0, =0x06010000      @ OBJ tile0 = red
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ sprite (100,76) 16x16 tile0
    ldr r0, =0x07000000
    ldr r1, =0x004C          @ y=76
    strh r1, [r0]
    ldr r1, =0x4064          @ x=100, size1 (16x16)
    strh r1, [r0, #2]
    ldr r1, =0x0000
    strh r1, [r0, #4]
    @ WIN0H: x 0-110 (X2=110=0x6E)
    ldr r1, =0x0068
    strh r1, [r12, #0x40]
    ldr r1, =0x00A0          @ WIN0V y 0-160
    strh r1, [r12, #0x44]
    @ WININ: WIN0 = 0x0F (OBJ bit4=0, disabled)
    ldr r1, =0x000F
    strh r1, [r12, #0x48]
    @ WINOUT: outside = 0x1F (OBJ bit4=1, enabled)
    ldr r1, =0x001F
    strh r1, [r12, #0x4A]
    @ DISPCNT: OBJ(0x1000) + WIN0(0x2000) + 1D(0x40)
    ldr r1, =0x3040
    strh r1, [r12]
forever:
    b forever
