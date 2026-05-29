.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x06000000
    ldr r1, =0x001F001F      @ all red
    ldr r3, =19200
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r0, =0x06009600      @ row 80 green (offset 38400)
    ldr r1, =0x03E003E0
    mov r3, #120
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    ldr r1, =0x0100
    strh r1, [r12, #0x20]    @ PA=256
    mov r1, #0
    strh r1, [r12, #0x22]    @ PB=0
    mov r1, #64
    strh r1, [r12, #0x24]    @ PC=64
    ldr r1, =0x0100
    strh r1, [r12, #0x26]    @ PD=256
    mov r1, #0
    str r1, [r12, #0x28]
    str r1, [r12, #0x2C]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
