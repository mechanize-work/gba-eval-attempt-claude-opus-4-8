@ GBA PSG audio test: play a square wave on channel 2 + a tone on channel 1.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4

main:
    ldr r0, =0x04000000

    @ Master sound enable: SOUNDCNT_X (0x84) = 0x80
    mov r1, #0x80
    strh r1, [r0, #0x84]

    @ SOUNDCNT_H (0x82): PSG volume 100% (bits0-1=2)
    mov r1, #2
    strh r1, [r0, #0x82]

    @ SOUNDCNT_L (0x80): ch1+ch2 enabled L+R, master vol 7/7
    ldr r1, =0x2200            @ vol 7/7, ch1+ch2 on both sides
    strh r1, [r0, #0x80]

    @ Channel 2: SOUND2CNT_L (0x68) duty=2, env initial vol=15, no sweep on env
    ldr r1, =0xF080            @ (2<<6)|(15<<12)
    strh r1, [r0, #0x68]
    @ SOUND2CNT_H (0x6C): freq=0x6D6 (~440Hz), trigger bit15, length disabled
    ldr r1, =0x86D6
    strh r1, [r0, #0x6C]

    @ Channel 1: SOUND1CNT_L (0x60) sweep off
    mov r1, #0
    strh r1, [r0, #0x60]
    @ SOUND1CNT_H (0x62): duty=2, env vol=12
    ldr r1, =0xC080            @ (2<<6)|(12<<12)
    strh r1, [r0, #0x62]
    @ SOUND1CNT_X (0x64): freq=0x500, trigger
    mov r1, #0
    strh r1, [r0, #0x64]

    @ DISPCNT: forced blank off, backdrop black (mode 0, nothing enabled)
    mov r1, #0
    strh r1, [r0]

forever:
    b forever
