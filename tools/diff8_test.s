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
    swi 0x160000               @ Diff8bitUnFilter
    ldr r0, =0x02000000
    ldr r6, =0x06000000
    ldrh r2, [r0]
    strh r2, [r6]
    ldrh r2, [r0, #2]
    strh r2, [r6, #2]
    ldrh r2, [r0, #4]
    strh r2, [r6, #4]
    ldrh r2, [r0, #6]
    strh r2, [r6, #6]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
.align 2
diffdata:
    .byte 0x81, 0x08, 0x00, 0x00
    .byte 10, 5, 3, 250, 1, 1, 1, 1
