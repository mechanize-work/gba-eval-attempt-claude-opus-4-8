.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x07000000
    ldr r2, =0x1234
    strh r2, [r1]              @ OAM[0] = 0x1234
    ldr r1, =0x07000400        @ +1KB mirror
    ldrh r6, [r1]
    ldr r1, =0x05000000
    ldr r2, =0x7FFF
    and r6, r6, r2
    strh r6, [r1]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
