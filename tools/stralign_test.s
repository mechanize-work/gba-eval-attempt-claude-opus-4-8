.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r1, =0x02000000
    mov r0, #0
    str r0, [r1]
    str r0, [r1, #4]
    ldr r0, =0xAABBCCDD
    add r1, r1, #2           @ unaligned 0x02000002
    str r0, [r1]            @ ARM7: forced to 0x02000000, full word
    ldr r1, =0x02000000
    ldr r0, [r1]           @ read back -> 0xAABBCCDD
    ldr r2, =0x7FFF
    and r3, r0, r2          @ 0x4CDD
    ldr r1, =0x05000000
    strh r3, [r1]
    ldr r2, =0x04000000
    mov r1, #0
    strh r1, [r2]
forever:
    b forever
    .ltorg
