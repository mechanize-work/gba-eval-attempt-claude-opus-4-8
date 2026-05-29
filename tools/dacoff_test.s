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
    ldr r1, =0xF000           @ ch1 env vol15 DAC on
    strh r1, [r12, #0x62]
    ldr r1, =0x1177
    strh r1, [r12, #0x80]
    ldr r1, =0x8400           @ ch1 trigger
    strh r1, [r12, #0x64]
    ldr r3, =20000
1:  subs r3, r3, #1
    bne 1b
    mov r1, #0
    strh r1, [r12, #0x62]     @ SOUND1CNT_H=0 -> DAC off -> disable channel
    ldrh r2, [r12, #0x84]
    ldr r3, =0x05000000
    strh r2, [r3]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
