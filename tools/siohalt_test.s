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
    ldr r1, =0x03007FFC
    ldr r2, =irq_handler
    str r2, [r1]
    ldr r3, =0x04000200
    mov r1, #0x80             @ IE = serial
    strh r1, [r3]
    mov r1, #1
    strh r1, [r3, #8]         @ IME
    mov r1, #0
    strh r1, [r0]             @ DISPCNT=0 (show backdrop)
    ldr r5, =0x04000128
    ldr r1, =0x4081           @ SIOCNT: internal clk + start + IRQ enable
    strh r1, [r5]
    @ HALT (write 0 to HALTCNT 0x301) - wait for the serial IRQ
    ldr r6, =0x04000301
    mov r1, #0
    strb r1, [r6]
forever:
    b forever
    .ltorg
irq_handler:
    ldr r0, =0x04000202
    ldrh r1, [r0]
    strh r1, [r0]
    ldr r2, =0x03007FF8
    ldrh r3, [r2]
    orr r3, r3, r1
    strh r3, [r2]
    ldr r0, =0x05000000
    ldr r1, =0x03E0           @ green
    strh r1, [r0]
    bx lr
    .ltorg
