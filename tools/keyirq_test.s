.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r10, =0x04000132
    ldr r11, =0x04000202
    ldr r1, =0x4001            @ KEYCNT: A mask + IRQ enable
    strh r1, [r10]
    ldr r0, =0x05000000
    mov r1, #0
    strh r1, [r12]             @ DISPCNT=0
loop:
    ldrh r2, [r11]             @ read IF
    tst r2, #0x1000            @ keypad IRQ flag
    moveq r1, #0x1F            @ red if not fired
    movne r1, #0x3E0           @ green if fired
    strh r1, [r0]
    b loop
