.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ EWRAM: write base, read 256KB mirror
    ldr r1, =0x02000000
    ldr r2, =0x0011
    strh r2, [r1]
    ldr r1, =0x02040000        @ +256KB mirror
    ldrh r6, [r1]
    @ IWRAM: write base, read 32KB mirror
    ldr r1, =0x03000000
    ldr r2, =0x0022
    strh r2, [r1]
    ldr r1, =0x03008000        @ +32KB mirror
    ldrh r7, [r1]
    @ Palette: write base, read 1KB mirror
    ldr r1, =0x05000000
    ldr r2, =0x0044
    strh r2, [r1]
    ldr r1, =0x05000400        @ +1KB mirror
    ldrh r8, [r1]
    @ fold
    eor r6, r6, r7
    eor r6, r6, r8
    ldr r1, =0x7FFF
    and r6, r6, r1
    ldr r1, =0x05000000
    strh r6, [r1]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
