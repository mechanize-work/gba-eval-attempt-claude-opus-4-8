.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ Fill 16KB EWRAM buffer: 32 bytes +50, 32 bytes -50
    ldr r0, =0x03000000
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
    @ Timer0: overflow every 1024 cyc (16384 Hz)
    ldr r11, =0x04000100
    ldr r1, =0xFC00
    strh r1, [r11]
    ldr r1, =0x0080
    strh r1, [r11, #2]
    @ DMA2: src=buffer dst=FIFO_B(0x040000A4) special repeat 32bit
    ldr r1, =0x03000000
    str r1, [r12, #0xC8]
    ldr r1, =0x040000A4
    str r1, [r12, #0xCC]
    ldr r1, =0xB6400004
    str r1, [r12, #0xD0]
    @ SOUNDCNT_H: DS B L+R(0x3000) + B 100%(0x08) + timer0(bit14=0)
    ldr r1, =0x3008
    strh r1, [r12, #0x82]
    mov r1, #0x80
    strh r1, [r12, #0x84]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
