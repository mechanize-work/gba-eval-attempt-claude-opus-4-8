.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    adr r0, lzdata
    ldr r1, =0x02000000
    swi 0x110000
    ldr r0, =0x02000000
    ldrh r2, [r0, #4]    @ decompressed [4] = back-ref copied 'A','B' = 0x4241
    ldr r3, =0x05000000
    strh r2, [r3]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
.align 2
lzdata:
    .byte 0x10, 0x08, 0x00, 0x00   @ size 8
    .byte 0x08, 0x41, 0x42, 0x43, 0x44, 0x10, 0x03  @ ABCD + backref(disp=3,len=4)->ABCD
