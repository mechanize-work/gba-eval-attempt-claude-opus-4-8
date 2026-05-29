@ VCount-match IRQ raster split: IRQ at line 80 recolors backdrop red->green.
@ Top half (0-79) red, bottom (80-159) green. Tests LYC IRQ timing vs oracle.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4

main:
    ldr r0, =0x04000000
    @ backdrop = red
    ldr r1, =0x05000000
    ldr r2, =0x001F
    strh r2, [r1]
    @ user IRQ handler pointer @ 0x03007FFC
    ldr r1, =0x03007FFC
    ldr r2, =irq_handler
    str r2, [r1]
    @ DISPSTAT: LYC=80, VCount IRQ enable (bit5) + VBlank IRQ enable (bit3)
    ldr r1, =0x5028
    strh r1, [r0, #4]
    @ IE = VCount(bit2)|VBlank(bit0), IME = 1 (base r3 to avoid >255 offset)
    ldr r3, =0x04000200
    mov r1, #5
    strh r1, [r3]
    mov r1, #1
    strh r1, [r3, #8]
    @ DISPCNT = 0 (backdrop visible)
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
    .ltorg

irq_handler:
    ldr r0, =0x04000202        @ IF (separate base, offset >255 trap)
    ldrh r1, [r0]              @ which IRQ(s)
    strh r1, [r0]              @ ack
    ldr r2, =0x03007FF8        @ BIOS IF mirror
    ldrh r3, [r2]
    orr r3, r3, r1
    strh r3, [r2]
    ldr r0, =0x05000000
    tst r1, #4                 @ VCount?
    ldrne r2, =0x03E0          @ green (line 80+)
    ldreq r2, =0x001F          @ red (VBlank: restore for next frame)
    strh r2, [r0]
    bx lr
    .ltorg
