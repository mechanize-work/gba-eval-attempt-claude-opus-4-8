.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r4, =0x04000100        @ TM0CNT_L
    ldr r5, =0x04000102        @ TM0CNT_H
    mov r1, #0
    strh r1, [r4]              @ reload = 0
    ldr r1, =0x0083           @ enable | prescaler 1024 (slow)
    strh r1, [r5]
    ldr r1, =0x4000
    strh r1, [r4]              @ write new reload=0x4000 (must NOT change counter)
    ldrh r3, [r4]              @ read counter: should be ~0, not 0x4000
    ldr r1, =0x7FFF
    and r3, r3, r1
    ldr r1, =0x05000000
    strh r3, [r1]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
