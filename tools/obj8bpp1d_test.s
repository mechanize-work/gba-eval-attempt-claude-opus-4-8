.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000200
    ldr r1, =0x001F
    strh r1, [r0, #2]
    ldr r1, =0x03E0
    strh r1, [r0, #4]
    @ tn0+tn2 (0x06010000,128B) red, tn4+tn6 (0x06010080,128B) green
    ldr r0, =0x06010000
    ldr r1, =0x01010101
    mov r3, #32
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r0, =0x06010080
    ldr r1, =0x02020202
    mov r3, #32
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    ldr r0, =0x07000000
    ldr r1, =0x2050
    strh r1, [r0]
    ldr r1, =0x4064
    strh r1, [r0, #2]
    ldr r1, =0x0000
    strh r1, [r0, #4]
    ldr r1, =0x1040         @ DISPCNT mode0 OBJ 1D(bit6)
    strh r1, [r12]
forever:
    b forever
