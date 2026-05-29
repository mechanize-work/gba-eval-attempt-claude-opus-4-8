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
    ldr r6, =0x06000000
    ldr r4, =0x03000000
    ldr r5, =0x12345678
    str r5, [r4]
    ldr r2, =0x00007ABC
    swp r1, r2, [r4]           @ r1 = old [r4] = 0x12345678, [r4] = 0x7ABC
    strh r1, [r6]
    ldrh r3, [r4]
    strh r3, [r6, #2]
    add r4, r4, #0x20
    mov r5, #0x6E
    strb r5, [r4]
    mov r2, #0x33
    swpb r1, r2, [r4]          @ r1 = old byte 0x6E, [r4] = 0x33
    strh r1, [r6, #4]
    ldrb r3, [r4]
    strh r3, [r6, #6]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
