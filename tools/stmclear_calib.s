.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r2, =0x02000000        @ EWRAM base
    mov r3, #0
    ldr r0, =200000            @ iterations
loop:
    stmia r2!, {r3}            @ store r3 to [r2], r2 += 4 (sequential addresses)
    sub r2, r2, #4             @ keep r2 in range (overwrite same area)
    subs r0, r0, #1
    bne loop
    ldr r2, =0x05000000
    ldr r1, =0x001F
    strh r1, [r2]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
