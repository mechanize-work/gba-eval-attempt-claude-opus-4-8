.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r0, #0
    strh r0, [r12]
    @ src @ 0x02000000: words 1..8
    ldr r1, =0x02000000
    mov r3, #0
    mov r4, #1
1:  str r4, [r1, r3]
    add r4, r4, #1
    add r3, r3, #4
    cmp r3, #32
    blt 1b
    @ clear dst
    ldr r1, =0x02000100
    mov r2, #0
    mov r3, #0
2:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 2b
    @ CpuFastSet copy count=5
    ldr r0, =0x02000000
    ldr r1, =0x02000100
    mov r2, #5
    swi 0x0C0000
    @ SUM dst[0..8]
    ldr r1, =0x02000100
    mov r4, #0
    mov r3, #0
3:  ldr r5, [r1, r3]
    add r4, r4, r5
    add r3, r3, #4
    cmp r3, #32
    blt 3b
    ldr r1, =0x7FFF
    and r4, r4, r1
    ldr r1, =0x05000000
    strh r4, [r1]
forever:
    b forever
