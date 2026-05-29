.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r11, =0x04000202
    ldr r10, =0x04000100
    ldr r1, =0xFFF0
    strh r1, [r10]             @ TM0 reload (overflows after 16 ticks)
    ldr r1, =0x00C0
    strh r1, [r10, #2]         @ TM0CNT = enable + IRQ + prescaler0
    ldr r0, =0x05000000
    mov r1, #0
    strh r1, [r12]
loop:
    ldrh r2, [r11]
    tst r2, #0x08              @ timer0 IRQ flag (IF bit3)
    moveq r1, #0x1F
    movne r1, #0x3E0
    strh r1, [r0]
    b loop
