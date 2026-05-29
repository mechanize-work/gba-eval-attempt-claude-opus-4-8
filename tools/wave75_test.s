.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    mov r1, #0x80
    strh r1, [r0, #0x84]
    mov r1, #2
    strh r1, [r0, #0x82]
    ldr r1, =0x4477
    strh r1, [r0, #0x80]
    mov r1, #0x80
    strh r1, [r0, #0x70]
    @ ramp 0..15 twice into wave RAM (high-nibble first): bytes 01 23 45 67 89 AB CD EF
    ldr r2, =0x04000090
    ldr r3, =0x67452301
    str r3, [r2]
    ldr r3, =0xEFCDAB89
    str r3, [r2, #4]
    ldr r3, =0x67452301
    str r3, [r2, #8]
    ldr r3, =0xEFCDAB89
    str r3, [r2, #12]
    mov r1, #0xC0
    strh r1, [r0, #0x70]
    ldr r1, =0xA000          @ force 75% (bit15) (code 2)
    strh r1, [r0, #0x72]
    ldr r1, =0x8400
    strh r1, [r0, #0x74]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
