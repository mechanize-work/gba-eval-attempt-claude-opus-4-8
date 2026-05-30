.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r1, =0x02000000
    ldr r0, =0x12345678
    str r0, [r1]
    add r1, r1, #1           @ odd addr 0x02000001
    ldrh r0, [r1]           @ ARM7: (halfword@0x02000000=0x5678) ror 8 = 0x78000056
    ldr r2, =0x7FFF
    and r3, r0, r2          @ 0x78000056 & 0x7FFF = 0x0056
    ldr r1, =0x05000000
    strh r3, [r1]
    ldr r2, =0x04000000
    mov r1, #0
    strh r1, [r2]
forever:
    b forever
    .ltorg
