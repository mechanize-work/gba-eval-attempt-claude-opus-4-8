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
    mov r0, #100
    mov r1, #7
    swi 0x060000               @ Div (changes BIOS exec state)
    mov r0, #0
    ldr r2, [r0]               @ read BIOS[0] after a SWI
    ldr r6, =0x06000000
    strh r2, [r6]
    mov r2, r2, lsr #16
    strh r2, [r6, #2]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
