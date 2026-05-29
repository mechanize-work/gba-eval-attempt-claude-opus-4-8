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
    ldr r5, =0x11111111
    str r5, [r4, #0x20]
    ldr r5, =0x22222222
    str r5, [r4, #0x24]
    ldr r5, =0x33333333
    str r5, [r4, #0x28]
    ldr r5, =0x44444444
    str r5, [r4, #0x2C]
    add r0, r4, #0x20
    add r1, r4, #0x40
    str r0, [r12, #0xB0]
    str r1, [r12, #0xB4]
    ldr r1, =0x84200004        @ cnt=4 src inc dest DEC(bit21) 32-bit enable
    str r1, [r12, #0xB8]
    ldr r6, =0x06000000
    ldrh r2, [r4, #0x40]
    strh r2, [r6]
    ldrh r2, [r4, #0x3C]
    strh r2, [r6, #2]
    ldrh r2, [r4, #0x34]
    strh r2, [r6, #4]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
