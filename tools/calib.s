.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ tight loop of 200000 iterations from ROM
    ldr r1, =200000
loop:
    subs r1, r1, #1
    bne loop
    @ after loop: set backdrop red
    ldr r2, =0x05000000
    ldr r3, =0x001F
    strh r3, [r2]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
