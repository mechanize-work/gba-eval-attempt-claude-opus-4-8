.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r1, =0x0403            @ mode 3, BG2
    strh r1, [r12]
    ldr r2, =0x06000000
    ldr r3, =0x7FFF            @ white
    ldr r0, =38400
fill:
    strh r3, [r2]
    add r2, r2, #2
    subs r0, r0, #1
    bne fill
forever:
    b forever
