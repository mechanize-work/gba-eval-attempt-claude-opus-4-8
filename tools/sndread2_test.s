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
    ldr r1, =0xF03F           @ SOUND1CNT_H: env 0xF0 + duty 0 + length 0x3F
    strh r1, [r12, #0x62]
    ldrh r2, [r12, #0x62]     @ readback: length bits0-5 read as 0 -> expect 0xF000
    ldr r3, =0x05000000
    strh r2, [r3]             @ backdrop
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
