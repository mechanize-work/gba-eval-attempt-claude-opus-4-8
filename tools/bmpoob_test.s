.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x7FFF          @ backdrop white
    strh r1, [r0]
    ldr r0, =0x06000000
    ldr r1, =0x001F001F      @ bitmap all red
    ldr r3, =19200
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x0100
    strh r1, [r12, #0x20]
    mov r1, #0
    strh r1, [r12, #0x22]
    strh r1, [r12, #0x24]
    ldr r1, =0x0100
    strh r1, [r12, #0x26]
    ldr r1, =0xFFFFCE00      @ refX = -50.0
    str r1, [r12, #0x28]
    mov r1, #0
    str r1, [r12, #0x2C]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
