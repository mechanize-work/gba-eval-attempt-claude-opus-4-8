@ PSG master-volume test: ch2 square routed L+R, but master vol L=3 R=7.
@ Tests SOUNDCNT_L bits 0-2 (right) / 4-6 (left) scaling curve.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4

main:
    ldr r0, =0x04000000

    mov r1, #0x80
    strh r1, [r0, #0x84]       @ SOUNDCNT_X master enable

    mov r1, #2
    strh r1, [r0, #0x82]       @ SOUNDCNT_H PSG 100%

    @ SOUNDCNT_L: ch2 L+R enable (bits13,9), vol L=3 (bits4-6), R=7 (bits0-2)
    ldr r1, =0x2237
    strh r1, [r0, #0x80]

    @ ch2 square: duty=2, vol=15
    ldr r1, =0xF080
    strh r1, [r0, #0x68]
    ldr r1, =0x86D6           @ freq, trigger
    strh r1, [r0, #0x6C]

    mov r1, #0
    strh r1, [r0]
forever:
    b forever
