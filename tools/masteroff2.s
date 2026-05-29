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
    ldr r1, =0xF080           @ ch1 duty50 + env vol15
    strh r1, [r12, #0x62]
    ldr r1, =0x1177           @ SOUNDCNT_L ch1 L/R vol7
    strh r1, [r12, #0x80]
    ldr r1, =0x8400           @ ch1 freq + trigger
    strh r1, [r12, #0x64]
    @ delay ~10 frames
    ldr r3, =200000
1:  subs r3, r3, #1
    bne 1b
    @ disable master -> should silence ALL sound
    mov r1, #0
    strh r1, [r12, #0x84]
forever:
    b forever
