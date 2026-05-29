.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x001F
    strh r1, [r0]              @ backdrop = red
    mov r1, #0
    strh r1, [r12]             @ DISPCNT=0
    ldr r10, =0x04000301
    mov r1, #0x80
    strb r1, [r10]             @ HALTCNT = STOP
    ldr r1, =0x03E0
    strh r1, [r0]              @ backdrop = green (only runs if NOT halted)
forever:
    b forever
