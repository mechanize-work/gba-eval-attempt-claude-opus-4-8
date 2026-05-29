.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x02000000
    mov r2, #0
    str r2, [r1]              @ clear mem
    @ str rd==rn post-index: stored value = ORIGINAL r1 (before writeback)
    str r1, [r1], #4         @ stores 0x02000000 at mem[0x02000000], then r1+=4
    ldr r1, =0x02000000
    ldr r3, [r1]             @ read back what was stored
    mov r4, r3, lsr #16
    eor r3, r3, r4
    ldr r2, =0x7FFF
    and r3, r3, r2
    ldr r2, =0x05000000
    strh r3, [r2]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
