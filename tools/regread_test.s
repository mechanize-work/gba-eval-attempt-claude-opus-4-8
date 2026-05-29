.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r1, =0xFFFF
    strh r1, [r12, #REGOFF]
    ldrh r2, [r12, #REGOFF]    @ readback
    mov r1, #0
    strh r1, [r12, #REGOFF]    @ restore so it doesn't affect rendering
    ldr r3, =0x05000000
    strh r2, [r3]              @ backdrop = readback value
    mov r1, #0
    strh r1, [r12]             @ DISPCNT=0 (clear BIOS forced-blank)
    b forever
forever:
    b forever
