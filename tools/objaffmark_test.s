.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x03E0         @ palette[0] = GREEN marker
    strh r1, [r0]
    mov r1, #0
    strh r1, [r12]          @ DISPCNT=0
    adr r0, affsrc
    ldr r1, =0x02000000
    mov r2, #1
    mov r3, #2
    swi 0x0F0000
    ldr r0, =0x02000000
    ldrh r2, [r0]
    ldr r3, =0x05000000
    strh r2, [r3]           @ palette[0] = PA (overwrites green IF reached)
forever:
    b forever
.align 2
affsrc:
    .hword 0x0100, 0x0100, 0x0000, 0x0000
