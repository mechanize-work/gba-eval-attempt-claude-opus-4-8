.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r11, =0x04000202
    ldr r4, =0x03000000
    ldr r1, =0x12345678
    str r1, [r4]
    str r4, [r12, #0xB0]
    add r1, r4, #0x10
    str r1, [r12, #0xB4]
    ldr r1, =0xC4000001        @ enable + IRQ + 32-bit + immediate + count1
    str r1, [r12, #0xB8]
    mov r1, #0
    strh r1, [r12]             @ DISPCNT=0
    ldr r0, =0x05000000
loop:
    ldrh r2, [r11]
    tst r2, #0x100             @ DMA0 IRQ flag (IF bit8)
    moveq r1, #0x1F
    movne r1, #0x3E0
    strh r1, [r0]
    b loop
