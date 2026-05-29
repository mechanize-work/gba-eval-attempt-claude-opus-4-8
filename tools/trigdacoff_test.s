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
    mov r1, #0
    strh r1, [r12, #0x62]     @ SOUND1CNT_H = 0 (DAC OFF: env vol 0 + dir 0)
    ldr r1, =0x1177
    strh r1, [r12, #0x80]
    ldr r1, =0x8400           @ trigger ch1 (with DAC off -> should NOT enable)
    strh r1, [r12, #0x64]
    ldrh r2, [r12, #0x84]
    ldr r3, =0x05000000
    strh r2, [r3]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
