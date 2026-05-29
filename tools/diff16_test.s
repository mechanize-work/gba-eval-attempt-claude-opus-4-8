.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0
    strh r1, [r12]
    adr r0, diffdata
    ldr r1, =0x02000000
    swi 0x180000               @ Diff16bitUnFilter
    ldr r0, =0x02000000
    ldr r6, =0x06000000
    ldrh r2, [r0]
    strh r2, [r6]
    ldrh r2, [r0, #2]
    strh r2, [r6, #2]
    ldrh r2, [r0, #4]
    strh r2, [r6, #4]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
.align 2
diffdata:
    .byte 0x82, 0x06, 0x00, 0x00   @ Diff16, size 6 bytes (3 halfwords)
    .hword 0x0100, 0x0050, 0xFF00  @ deltas
