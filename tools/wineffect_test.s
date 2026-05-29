.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x06000000
    ldr r1, =0x42104210       @ gray (16,16,16)
    ldr r2, =19200
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b
    ldr r1, =0x5028
    strh r1, [r12, #0x40]      @ WIN0H x1=80 x2=40? -> use 80,160
    ldr r1, =0x50A0
    strh r1, [r12, #0x40]      @ WIN0H x1=80 x2=160
    ldr r1, =0x00A0
    strh r1, [r12, #0x44]      @ WIN0V 0..160
    mov r1, #0x04
    strh r1, [r12, #0x48]      @ WININ: BG2, effects OFF (bit5=0)
    ldr r1, =0x24
    strh r1, [r12, #0x4A]      @ WINOUT: BG2 + effects ON (bit5=1)
    mov r1, #0x84
    strh r1, [r12, #0x50]      @ BLDCNT: mode2 brighten, BG2 1st target
    mov r1, #0x10
    strh r1, [r12, #0x54]      @ BLDY max
    ldr r1, =0x2403
    strh r1, [r12]             @ mode3 + BG2 + win0
forever:
    b forever
