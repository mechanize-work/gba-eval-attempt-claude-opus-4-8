.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x0014          @ backdrop R20
    strh r1, [r0]
    @ BLDCNT: darken(0xC0) + BD 1st target(0x20) = 0xE0
    ldr r1, =0x00E0
    strh r1, [r12, #0x50]
    mov r1, #5               @ EVY 5
    strh r1, [r12, #0x54]
    ldr r1, =0x0000          @ mode0, no BG -> whole screen = backdrop
    strh r1, [r12]
forever:
    b forever
