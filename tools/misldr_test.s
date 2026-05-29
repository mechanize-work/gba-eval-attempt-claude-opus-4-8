.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x12345678
    ldr r4, =0x02000000
    str r0, [r4]
    add r4, r4, #2          @ misaligned 0x02000002
    ldr r0, [r4]            @ rotate right 16 -> 0x56781234
    ldr r2, =0x05000000
    strh r0, [r2]           @ palette[0] = 0x1234
    @ also test misaligned-by-1 -> palette[1]
    ldr r4, =0x02000000
    add r4, r4, #1
    ldr r0, [r4]            @ rotate right 8 -> 0x78123456
    strh r0, [r2, #2]       @ palette[1] = 0x3456
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
