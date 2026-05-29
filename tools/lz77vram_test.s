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
    adr r0, lzdata
    ldr r1, =0x06000000        @ dest = VRAM
    swi 0x120000               @ LZ77UnCompVram
    ldr r1, =0x0403            @ mode 3 -> VRAM shows as pixels
    strh r1, [r12]
forever:
    b forever
.align 2
lzdata:
    .byte 0x10, 0x08, 0x00, 0x00
    .byte 0x00, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48
