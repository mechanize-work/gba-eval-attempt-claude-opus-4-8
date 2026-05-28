.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    mov r1, #0x80
    strh r1, [r0, #0x84]
    mov r1, #2
    strh r1, [r0, #0x82]
    ldr r1, =0x4477          @ ch3 L+R, vol 7/7
    strh r1, [r0, #0x80]
    @ SOUND3CNT_L: DAC on, bank=0 -> access bank = 1 (writes go to bank1)
    mov r1, #0x80
    strh r1, [r0, #0x70]
    @ write ramp waveform to wave RAM (-> bank 1)
    ldr r2, =0x04000090
    ldr r3, =0xCDEF89AB
    mov r4, #0
wl:
    str r3, [r2, r4]
    add r4, r4, #4
    cmp r4, #16
    blt wl
    @ now set bank=1 (playback reads bank1 = just written), DAC on
    mov r1, #0xC0
    strh r1, [r0, #0x70]
    @ volume 100%
    ldr r1, =0x2000
    strh r1, [r0, #0x72]
    @ freq + trigger
    ldr r1, =0x8400
    strh r1, [r0, #0x74]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
