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
    swi 0x110000          @ LZ77UnCompWram (SWI 0x11)
    ldr r0, =0x02000000
    ldrh r2, [r0]         @ first decompressed halfword
    ldr r3, =0x05000000
    strh r2, [r3]
    ldrh r2, [r0, #2]     @ second halfword -> palette[1] won't show; use frame later
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
.align 2
lzdata:
    .byte 0x10, 0x08, 0x00, 0x00   @ LZ77 header: type 0x10, decompressed size 8
    .byte 0x00, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48  @ flag=0 (8 literals) ABCDEFGH
