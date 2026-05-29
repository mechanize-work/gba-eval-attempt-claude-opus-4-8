.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0x80
    strh r1, [r12, #0x84]
    mov r1, #2
    strh r1, [r12, #0x82]
    ldr r1, =0x2277
    strh r1, [r12, #0x80]
    @ SOUND2CNT_L (0x68): duty2(0x80), env period4(0x400), env_dir up(0x800), init vol 0
    ldr r1, =0x0C80
    strh r1, [r12, #0x68]
    @ SOUND2CNT_H (0x6C): freq1024 + trigger
    ldr r1, =0x8400
    strh r1, [r12, #0x6C]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
