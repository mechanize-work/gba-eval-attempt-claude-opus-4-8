.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0x80
    strh r1, [r12, #0x84]    @ master enable
    ldr r1, =0x0B04          @ DS A en + 100% + RESET bit11
    strh r1, [r12, #0x82]
    ldrh r2, [r12, #0x82]    @ read back SOUNDCNT_H
    ldr r3, =0x05000000
    strh r2, [r3]            @ backdrop = readback
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
