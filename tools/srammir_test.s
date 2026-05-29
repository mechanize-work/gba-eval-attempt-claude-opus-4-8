.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x0E000000
    ldr r1, =0x0E008000        @ +32KB (potential mirror)
    mov r2, #0x5A
    strb r2, [r0]              @ write SRAM[0] = 0x5A
    ldrb r3, [r1]              @ read mirror
    ldr r1, =0x05000000
    strh r3, [r1]
    ldr r0, =0x04000000
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
