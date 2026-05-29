.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r10, =0x04000300
    ldrb r2, [r10]             @ read POSTFLG
    ldr r3, =0x05000000
    strh r2, [r3]              @ backdrop low = POSTFLG (1 -> dark red, 0 -> black)
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
