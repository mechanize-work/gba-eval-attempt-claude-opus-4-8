.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x02000000
    .word 0xE8A00000          @ stmia r0!, {} (empty rlist) - ARMv4: stores r15, r0 += 0x40
    ldr r1, =0x7FFF
    and r3, r0, r1            @ r0 should be 0x02000040 -> &0x7FFF = 0x40
    ldr r1, =0x05000000
    strh r3, [r1]
    ldr r2, =0x04000000
    mov r1, #0
    strh r1, [r2]
forever:
    b forever
