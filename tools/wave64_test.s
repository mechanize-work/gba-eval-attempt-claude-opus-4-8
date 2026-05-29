@ Wave channel 64-sample (dimension) mode: bank0 ramp-up, bank1 ramp-down.
@ A 32-vs-64 bug or wrong bank order changes the waveform shape. Compare audio.
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

    @ select bank0 for RAM write (64-mode bit5, dac bit7, bank0)
    ldr r1, =0x00A0
    strh r1, [r0, #0x70]
    @ bank0 = ramp up 0..15,0..15
    ldr r1, =0x67452301
    str r1, [r0, #0x90]
    ldr r1, =0xEFCDAB89
    str r1, [r0, #0x94]
    ldr r1, =0x67452301
    str r1, [r0, #0x98]
    ldr r1, =0xEFCDAB89
    str r1, [r0, #0x9C]

    @ select bank1 for RAM write (bit6 set)
    ldr r1, =0x00E0
    strh r1, [r0, #0x70]
    @ bank1 = ramp down 15..0,15..0
    ldr r1, =0x98BADCFE
    str r1, [r0, #0x90]
    ldr r1, =0x10325476
    str r1, [r0, #0x94]
    ldr r1, =0x98BADCFE
    str r1, [r0, #0x98]
    ldr r1, =0x10325476
    str r1, [r0, #0x9C]

    @ playback: 64-mode, bank0, dac on
    ldr r1, =0x00A0
    strh r1, [r0, #0x70]
    @ SOUND3CNT_H: volume 100% (bit13)
    ldr r1, =0x2000
    strh r1, [r0, #0x72]
    @ SOUNDCNT_L: ch3 L(bit14)+R(bit10), master vol 7/7
    ldr r1, =0x4477
    strh r1, [r0, #0x80]
    @ SOUND3CNT_X: freq=2000, trigger (bit15)
    ldr r1, =0xA7D0
    strh r1, [r0, #0x74]

    mov r1, #0
    strh r1, [r0]
forever:
    b forever
