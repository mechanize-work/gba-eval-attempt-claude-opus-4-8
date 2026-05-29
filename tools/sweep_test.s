.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ master sound enable
    mov r1, #0x80
    strh r1, [r12, #0x84]     @ SOUNDCNT_X
    @ PSG volume 100%, channel1 L+R
    ldr r1, =0x1177
    strh r1, [r12, #0x80]     @ SOUNDCNT_L
    mov r1, #2
    strh r1, [r12, #0x82]     @ SOUNDCNT_H (PSG 100%)
    @ SOUND1CNT_L: sweep shift=2, dir=increase(0), time=4
    ldr r1, =0x0042
    strh r1, [r12, #0x60]
    @ SOUND1CNT_H: duty=2 (0x80), env vol=15 (0xF000)
    ldr r1, =0xF080
    strh r1, [r12, #0x62]
    @ SOUND1CNT_X: freq=1024, trigger
    ldr r1, =0x8400
    strh r1, [r12, #0x64]
    mov r1, #0
    strh r1, [r12]            @ DISPCNT
forever:
    b forever
