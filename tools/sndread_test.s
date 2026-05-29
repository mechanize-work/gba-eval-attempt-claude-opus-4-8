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
    ldr r1, =0xF000
    strh r1, [r12, #0x62]     @ ch1 envelope
    ldr r1, =0x8500           @ SOUND1CNT_X: freq 0x500 + trigger bit15
    strh r1, [r12, #0x64]
    ldrh r2, [r12, #0x64]     @ readback (freq bits0-10 + trigger bit15 read as 0)
    ldr r3, =0x05000000
    strh r2, [r3]
    @ also SOUND1CNT_H (0x62): length bits0-5 read as 0
    ldr r1, =0xF03F           @ envelope + duty + length=0x3F
    strh r1, [r12, #0x62]
    ldrh r2, [r12, #0x62]
    strh r2, [r3, #2]         @ palette[1]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
