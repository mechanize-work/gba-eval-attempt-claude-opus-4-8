.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =30000            @ iterations
loop:
    ldr r1, =0x03000000
    stmia r1!, {r2-r9}        @ store 8 regs to EWRAM
    subs r0, r0, #1
    bne loop
    ldr r2, =0x05000000
    ldr r3, =0x001F
    strh r3, [r2]             @ backdrop red when done
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
