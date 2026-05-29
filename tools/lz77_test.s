.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
.align 2
lzdata:
    .byte 0x10, 0x08, 0x00, 0x00   @ LZ77 header: type1, decomp size=8
    .byte 0x00                      @ flag: 8 literals
    .byte 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48  @ A B C D E F G H
    .align 2
main:
    ldr r0, =lzdata
    ldr r1, =0x02000000
    swi #0x110000                    @ LZ77UnCompWram (8-bit write)
    @ read decompressed bytes 0 and 7
    ldr r1, =0x02000000
    ldrb r2, [r1]                    @ should be 0x41
    ldrb r3, [r1, #7]               @ should be 0x48
    @ checksum = r2 + (r3<<8)
    add r2, r2, r3, lsl #8
    ldr r4, =0x05000000
    strh r2, [r4]                    @ palette[0] = checksum
    mov r0, #0
    ldr r4, =0x04000000
    strh r0, [r4]
forever:
    b forever
