.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ master OFF (never enabled). Write SOUNDCNT_L while off.
    ldr r1, =0x1177
    strh r1, [r12, #0x80]
    ldrh r2, [r12, #0x80]    @ read back -> should be 0 (write ignored + read 0)
    ldr r3, =0x05000000
    strh r2, [r3]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
