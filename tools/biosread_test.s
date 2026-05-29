.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0
    strh r1, [r12]
    mov r0, #0
    ldrh r2, [r0]              @ read BIOS[0] low halfword (PC is in ROM -> protected)
    ldr r3, =0x05000000
    strh r2, [r3]
    ldrh r2, [r0, #4]          @ read BIOS[4]
    ldr r3, =0x06000000
    strh r2, [r3]
    mov r1, #0
    strh r1, [r12]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
