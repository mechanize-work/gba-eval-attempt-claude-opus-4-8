.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r3, =0x13579BDF
    mov r4, #1        @ multiplier with all bytes significant (m=4)
    ldr r0, =300000
loop:
    mul r2, r3, r4             @ MUL (m internal cycles)
    subs r0, r0, #1
    bne loop
    ldr r2, =0x05000000
    ldr r1, =0x001F
    strh r1, [r2]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
