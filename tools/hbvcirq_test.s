.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r11, =0x04000202
    ldr r1, =0x0030            @ DISPSTAT: HBlank IRQ(bit4) + VCount IRQ(bit5)
    strh r1, [r12, #0x04]
    mov r1, #0
    strh r1, [r12]             @ DISPCNT=0
    ldr r0, =0x05000000
loop:
    ldrh r2, [r11]
    and r2, r2, #0x06          @ HBlank(bit1)+VCount(bit2)
    cmp r2, #0x06              @ both set?
    moveq r1, #0x3E0           @ green if both fired
    movne r1, #0x1F            @ red otherwise
    strh r1, [r0]
    b loop
