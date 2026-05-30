.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    @ UMULL 0xFFFFFFFF * 0xFFFFFFFF = 0xFFFFFFFE_00000001
    ldr r0, =0xFFFFFFFF
    ldr r1, =0xFFFFFFFF
    umull r2, r3, r0, r1     @ r3=high=0xFFFFFFFE, r2=low=1
    ldr r5, =0x7FFF
    and r4, r3, r5           @ high & 0x7FFF = 0x7FFE
    @ verify low=1: if r2!=1 force a wrong marker
    cmp r2, #1
    bne bad
    ldr r1, =0x05000000
    strh r4, [r1]
    b done
bad:
    ldr r1, =0x05000000
    ldr r4, =0x1234
    strh r4, [r1]
done:
    ldr r2, =0x04000000
    mov r1, #0
    strh r1, [r2]
forever:
    b forever
    .ltorg
