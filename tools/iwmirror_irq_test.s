.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x05000000
    ldr r2, =0x001F           @ backdrop red
    strh r2, [r1]
    @ set IRQ handler ptr via the HIGH IWRAM mirror (0x03FFFFFC -> 0x03007FFC)
    ldr r1, =0x03FFFFFC
    ldr r2, =irq_handler
    str r2, [r1]
    ldr r3, =0x04000200
    mov r1, #1                 @ IE = VBlank
    strh r1, [r3]
    mov r1, #1
    strh r1, [r3, #8]          @ IME
    mov r1, #0x08
    strh r1, [r0, #4]          @ DISPSTAT VBlank IRQ enable
    mov r1, #0
    strh r1, [r0]              @ DISPCNT=0
forever:
    b forever
    .ltorg
irq_handler:
    ldr r0, =0x04000202
    mov r1, #1
    strh r1, [r0]              @ ack VBlank
    ldr r2, =0x03007FF8
    ldrh r3, [r2]
    orr r3, r3, #1
    strh r3, [r2]
    ldr r0, =0x05000000
    ldr r1, =0x03E0           @ green
    strh r1, [r0]
    bx lr
    .ltorg
