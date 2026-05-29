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
    mov r1, #2
    strh r1, [r12, #0x82]
    ldr r1, =0x1177           @ ch1 L+R, vol 7
    strh r1, [r12, #0x80]
    @ SOUND1CNT_L (0x60): shift=2, decrease(bit3), time=3 -> 0x3A
    ldr r1, =0x003A
    strh r1, [r12, #0x60]
    @ SOUND1CNT_H (0x62): duty2, env vol15 no decay
    ldr r1, =0xF080
    strh r1, [r12, #0x62]
    @ SOUND1CNT_X (0x64): freq 1024 + trigger
    ldr r1, =0x8400
    strh r1, [r12, #0x64]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
