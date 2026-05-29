.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r2, =0x02000000      @ r2 = base buffer
    ldr r0, =0xAAAA          @ r0 lower-numbered -> stored first
    stmia r2!, {r0, r2}      @ r2 not lowest in list: ARMv4 stores NEW (writeback) base value
    @ [buffer]=r0=0xAAAA ; [buffer+4]= base value stored (orig 0x02000000 vs new 0x02000008)
    ldr r1, =0x02000004
    ldr r0, [r1]
    ldr r1, =0x7FFF
    and r3, r0, r1           @ 0 = stored ORIGINAL base, 8 = stored NEW (written-back) base
    ldr r1, =0x05000000
    strh r3, [r1]
    ldr r2, =0x04000000
    mov r1, #0
    strh r1, [r2]            @ DISPCNT=0
forever:
    b forever
    .ltorg
