.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x02000000
    ldr r2, =0x12345678
    str r2, [r1]              @ mem[0x02000000] = 0x12345678
    @ ldr with rd==rn, post-index writeback: loaded value must win
    ldr r1, [r1], #4         @ r1 should = 0x12345678, NOT 0x02000004
    @ fold to 15-bit
    mov r4, r1, lsr #16
    eor r1, r1, r4
    ldr r2, =0x7FFF
    and r1, r1, r2
    ldr r2, =0x05000000
    strh r1, [r2]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
