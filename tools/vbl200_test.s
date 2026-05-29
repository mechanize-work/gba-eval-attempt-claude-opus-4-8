@ VBlank-flag-at-line-227 quirk: GBATEK says DISPSTAT bit0 is NOT set on line 227.
@ VCount IRQ at LYC=227 reads DISPSTAT bit0: green if cleared (quirk), red if set.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x05000000
    ldr r2, =0x001F           @ backdrop red (default = "flag still set / not reached")
    strh r2, [r1]
    ldr r1, =0x03007FFC
    ldr r2, =irq_handler
    str r2, [r1]
    @ DISPSTAT: LYC=227 (0xE300) + VCount IRQ enable (bit5 0x20)
    ldr r1, =0xC820
    strh r1, [r0, #4]
    ldr r3, =0x04000200
    mov r1, #4                 @ IE = VCount
    strh r1, [r3]
    mov r1, #1
    strh r1, [r3, #8]          @ IME
    mov r1, #0
    strh r1, [r0]              @ DISPCNT=0 (show backdrop)
forever:
    b forever
    .ltorg
irq_handler:
    ldr r0, =0x04000202        @ IF
    mov r1, #4
    strh r1, [r0]              @ ack VCount
    ldr r2, =0x03007FF8
    ldrh r3, [r2]
    orr r3, r3, #4
    strh r3, [r2]
    ldr r0, =0x04000000
    ldrh r1, [r0, #4]          @ DISPSTAT
    ldr r4, =0x05000000
    tst r1, #1                 @ VBlank flag (bit0)
    ldreq r2, =0x03E0          @ green: bit0 CLEAR on line 227 (quirk)
    ldrne r2, =0x001F          @ red: bit0 still set
    strh r2, [r4]
    bx lr
    .ltorg
