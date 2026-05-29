.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r3, #0
    mov r5, #4                 @ outer iterations
outer:
    ldr r2, =0x02000000        @ EWRAM base
    ldr r0, =65536             @ words to clear (256KB)
inner:
    stmia r2!, {r3}            @ sequential store, r2 += 4
    subs r0, r0, #1
    bne inner
    subs r5, r5, #1
    bne outer
    ldr r2, =0x05000000
    ldr r1, =0x001F
    strh r1, [r2]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
