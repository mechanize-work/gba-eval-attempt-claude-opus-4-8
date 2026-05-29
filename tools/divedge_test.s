.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r0, #0
    strh r0, [r12]            @ DISPCNT=0 FIRST (SWI-probe gotcha)
    @ case1: -100 / 7  -> q=-14 rem=-2
    ldr r0, =0xFFFFFF9C
    mov r1, #7
    swi 0x060000
    mov r4, r0
    mov r5, r1
    @ case2: 100 / -7  -> q=-14 rem=2
    mov r0, #100
    ldr r1, =0xFFFFFFF9
    swi 0x060000
    mov r6, r0
    mov r7, r1
    @ case3: 5 / 0  (div by zero - BIOS-specific result)
    mov r0, #5
    mov r1, #0
    swi 0x060000
    mov r8, r0
    mov r9, r1
    @ fold
    eor r4, r4, r5
    eor r4, r4, r6
    eor r4, r4, r7
    eor r4, r4, r8
    eor r4, r4, r9
    mov r10, r4, lsr #16
    eor r4, r4, r10
    ldr r0, =0x7FFF
    and r4, r4, r0
    ldr r0, =0x05000000
    strh r4, [r0]
forever:
    b forever
