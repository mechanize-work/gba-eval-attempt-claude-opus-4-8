.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x02000000
    ldr r4, =0x32323232
    ldr r5, =0xCECECECE
    ldr r2, =256
fill:
    mov r3, #8
1:  str r4, [r0], #4
    subs r3, r3, #1
    bne 1b
    mov r3, #8
2:  str r5, [r0], #4
    subs r3, r3, #1
    bne 2b
    subs r2, r2, #1
    bne fill
    @ Timer1 (0x04000104): reload 64512, enable, prescaler 0
    ldr r11, =0x04000104
    ldr r1, =0xFC00
    strh r1, [r11]
    ldr r1, =0x0080
    strh r1, [r11, #2]
    @ DMA1: src=buffer dst=FIFO_A cnt=4 special
    ldr r1, =0x02000000
    str r1, [r12, #0xBC]
    ldr r1, =0x040000A0
    str r1, [r12, #0xC0]
    ldr r1, =0xB6400004
    str r1, [r12, #0xC4]
    @ SOUNDCNT_H: DS A L+R(0x300) + 100%(0x04) + A from TIMER1 (bit10=0x400)
    ldr r1, =0x0704
    strh r1, [r12, #0x82]
    mov r1, #0x80
    strh r1, [r12, #0x84]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
