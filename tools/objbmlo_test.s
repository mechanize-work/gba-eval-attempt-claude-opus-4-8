.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000202
    ldr r1, =0x001F
    strh r1, [r0]
    ldr r0, =0x06000000
    ldr r1, =0x7C007C00
    ldr r2, =19200
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b                     @ bitmap blue
    ldr r0, =0x06010000        @ tile 0 data (overlaps bitmap) = red idx1
    ldr r1, =0x11111111
    mov r2, #8
2:  str r1, [r0], #4
    subs r2, r2, #1
    bne 2b
    ldr r0, =0x07000000
    ldr r1, =0x0032
    strh r1, [r0]
    ldr r1, =0x0032
    strh r1, [r0, #2]
    mov r1, #0                 @ tile 0 (<512, bitmap mode)
    strh r1, [r0, #4]
    ldr r1, =0x1443
    strh r1, [r12]
forever:
    b forever
