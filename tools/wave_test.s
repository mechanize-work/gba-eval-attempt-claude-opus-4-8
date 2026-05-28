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
    ldr r1, =0x8488           @ ch3 L+R (bit10 R, bit14 L), vol 7/7? -> 0x4400|0x77... use ch3 bits
    ldr r1, =0x4477           @ ch3 R(bit10)+L(bit14), vol7/7
    strh r1, [r0, #0x80]
    @ wave RAM: write a ramp pattern 0x0123456789ABCDEF...
    ldr r2, =0x04000090
    ldr r3, =0xCDEF89AB
    mov r4, #0
wloop:
    str r3, [r2, r4]
    add r4, r4, #4
    cmp r4, #16
    blt wloop
    @ SOUND3CNT_L (0x70): DAC on (bit7)
    mov r1, #0x80
    strh r1, [r0, #0x70]
    @ SOUND3CNT_H (0x72): volume 100% (bits13-14 = 1)
    ldr r1, =0x2000
    strh r1, [r0, #0x72]
    @ SOUND3CNT_X (0x74): freq, trigger
    ldr r1, =0x8400
    strh r1, [r0, #0x74]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
