.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    mov r1, #0x80
    strh r1, [r0, #0x84]      @ master enable
    mov r1, #2
    strh r1, [r0, #0x82]      @ PSG 100%
    ldr r1, =0x8877           @ ch4 L+R, vol 7/7
    strh r1, [r0, #0x80]
    ldr r1, =0xF000           @ SOUND4CNT_L env vol 15
    strh r1, [r0, #0x78]
    ldr r1, =0x8044           @ SOUND4CNT_H: shift=4, div=4, trigger
    strh r1, [r0, #0x7C]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
