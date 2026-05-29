@ Serial IRQ: internal-clock transfer with SIOCNT IRQ-enable (bit14) should
@ fire IF bit7 on completion -> handler turns backdrop red->green.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ backdrop red
    ldr r1, =0x05000000
    ldr r2, =0x001F
    strh r2, [r1]
    @ IRQ handler ptr
    ldr r1, =0x03007FFC
    ldr r2, =irq_handler
    str r2, [r1]
    @ IE = serial(bit7), IME=1 (base r3 = 0x04000200)
    ldr r3, =0x04000200
    mov r1, #0x80
    strh r1, [r3]
    mov r1, #1
    strh r1, [r3, #8]
    @ SIOCNT: internal clock(bit0)+start(bit7)+IRQ enable(bit14)
    ldr r5, =0x04000128
    ldr r1, =0x4081
    strh r1, [r5]
    @ disable forced blank so the backdrop shows
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
    .ltorg

irq_handler:
    ldr r0, =0x04000202        @ IF
    ldrh r1, [r0]
    strh r1, [r0]              @ ack
    ldr r2, =0x03007FF8
    ldrh r3, [r2]
    orr r3, r3, r1
    strh r3, [r2]
    ldr r0, =0x05000000
    ldr r1, =0x03E0           @ green
    strh r1, [r0]
    bx lr
    .ltorg
