.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0x80
    strh r1, [r12, #0x84]     @ master enable
    ldr r1, =0x2277           @ ch2 L+R (bit9 L, bit13 R = 0x2200) + vol 7,7
    strh r1, [r12, #0x80]
    mov r1, #2
    strh r1, [r12, #0x82]     @ PSG 100%
    @ SOUND2CNT_L: duty=2(0x80), env period=2(0x200), dir=decrease(0), init vol=15(0xF000)
    ldr r1, =0xF280
    strh r1, [r12, #0x68]
    @ SOUND2CNT_H: freq=1024, trigger
    ldr r1, =0x8400
    strh r1, [r12, #0x6C]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
