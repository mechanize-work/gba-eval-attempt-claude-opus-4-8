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
    ldr r4, =0x03000000
    @ 16-bit fill: dest = 0x1234 x4
    ldr r5, =0x00001234
    str r5, [r4]
    mov r0, r4
    add r1, r4, #0x20
    ldr r2, =0x01000004        @ count=4, fill(bit24), 16-bit
    swi 0x0B0000
    ldr r6, =0x06000000
    ldrh r0, [r4, #0x20]
    strh r0, [r6]
    ldrh r0, [r4, #0x26]       @ 4th halfword
    strh r0, [r6, #2]
    @ 32-bit copy: 2 words
    ldr r5, =0x00005678
    str r5, [r4, #0x40]
    ldr r5, =0x00001ABC
    str r5, [r4, #0x44]
    add r0, r4, #0x40
    add r1, r4, #0x60
    ldr r2, =0x04000002        @ count=2, copy, 32-bit(bit26)
    swi 0x0B0000
    ldrh r0, [r4, #0x60]
    strh r0, [r6, #4]
    ldrh r0, [r4, #0x64]
    strh r0, [r6, #6]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
