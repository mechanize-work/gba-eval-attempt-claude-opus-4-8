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
    ldr r1, =0x2277
    strh r1, [r12, #0x80]
    mov r1, #2
    strh r1, [r12, #0x82]
    @ SOUND2CNT_L: length=32(0x20), duty=2(0x80), env vol=15 no decay (period0)
    ldr r1, =0xF0A0
    strh r1, [r12, #0x68]
    @ SOUND2CNT_H: freq=1024, length-enable(bit14=0x4000), trigger(0x8000)
    ldr r1, =0xC400
    strh r1, [r12, #0x6C]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
