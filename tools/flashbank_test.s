@ Flash128 bank-switch round-trip: write 0x42->bank0[0], 0x37->bank1[0],
@ read both back. backdrop = (bank1<<8)|bank0 & 0x7FFF (=0x3742 if correct).
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4

main:
    ldr r0, =0x0E000000
    ldr r4, =0x0E005555
    ldr r5, =0x0E002AAA

    @ program 0x42 to bank0[0]
    mov r1, #0xAA
    strb r1, [r4]
    mov r1, #0x55
    strb r1, [r5]
    mov r1, #0xA0
    strb r1, [r4]
    mov r1, #0x42
    strb r1, [r0]

    @ bank switch -> 1
    bl bankcmd
    mov r1, #1
    strb r1, [r0]

    @ program 0x37 to bank1[0]
    mov r1, #0xAA
    strb r1, [r4]
    mov r1, #0x55
    strb r1, [r5]
    mov r1, #0xA0
    strb r1, [r4]
    mov r1, #0x37
    strb r1, [r0]

    @ bank switch -> 0
    bl bankcmd
    mov r1, #0
    strb r1, [r0]
    ldrb r6, [r0]             @ read bank0[0] -> expect 0x42

    @ bank switch -> 1
    bl bankcmd
    mov r1, #1
    strb r1, [r0]
    ldrb r7, [r0]             @ read bank1[0] -> expect 0x37

    @ backdrop = (r7<<8)|r6 masked
    mov r2, r7, lsl #8
    orr r2, r2, r6
    ldr r1, =0x7FFF
    and r2, r2, r1
    ldr r1, =0x05000000
    strh r2, [r1]
    ldr r0, =0x04000000
    mov r1, #0
    strh r1, [r0]
forever:
    b forever

bankcmd:
    mov r1, #0xAA
    strb r1, [r4]
    mov r1, #0x55
    strb r1, [r5]
    mov r1, #0xB0
    strb r1, [r4]
    bx lr
    .ltorg

sig:
    .asciz "FLASH1M_V"
