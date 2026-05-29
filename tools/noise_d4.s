.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0x80
    strh r1, [r12, #0x84]
    ldr r1, =0x8877          @ ch4 L+R (bit11 L, bit15 R = 0x8800) + vol
    strh r1, [r12, #0x80]
    mov r1, #2
    strh r1, [r12, #0x82]
    @ SOUND4CNT_L (0x78): env vol=15, no decay
    ldr r1, =0xF000
    strh r1, [r12, #0x78]
    @ SOUND4CNT_H (0x7C): width=7bit(bit3=0x08), freq div ratio, trigger(0x8000)
    ldr r1, =0x8024          @ trigger + width7(0x08) + shift/ratio (0x40 = shift 4)
    strh r1, [r12, #0x7C]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
