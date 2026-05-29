.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r1, =0x0405            @ mode 5, BG2 on
    strh r1, [r12]
    @ set a backdrop color (palette 0)
    ldr r2, =0x05000000
    ldr r1, =0x3DEF
    strh r1, [r2]
    @ Fill mode5 bitmap (160x128) at 0x06000000 with pattern
    ldr r2, =0x06000000
    mov r4, #0                 @ y
y5:
    mov r5, #0                 @ x
x5:
    add r6, r5, r4
    lsl r7, r4, #6
    eor r6, r6, r7
    ldr r8, =0x7FFF
    and r6, r6, r8
    strh r6, [r2]
    add r2, r2, #2
    add r5, r5, #1
    cmp r5, #160
    blt x5
    add r4, r4, #1
    cmp r4, #128
    blt y5
forever:
    b forever
