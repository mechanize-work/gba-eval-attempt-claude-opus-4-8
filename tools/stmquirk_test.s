.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ Test1: empty rlist STM -> base += 0x40
    ldr r0, =0x03000000
    .word 0xE8A00000          @ STMIA r0!, {}
    mov r8, r0                @ expect 0x03000040
    @ Test2: base-in-rlist, base NOT lowest
    ldr r5, =0x03000010
    ldr r0, =0x0000AAAA
    .word 0xE8A50021          @ STMIA r5!, {r0, r5}
    ldr r3, =0x03000014
    ldrh r7, [r3]             @ stored r5: old=0x0010, new=0x0018
    ldr r6, =0x06000000
    strh r8, [r6]
    strh r7, [r6, #2]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
