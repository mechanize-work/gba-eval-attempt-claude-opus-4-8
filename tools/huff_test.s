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
    adr r0, huffdata
    ldr r1, =0x06000000
    swi 0x130000               @ HuffUnComp -> VRAM
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
.align 2
huffdata:
    .byte 0x28, 0x04, 0x00, 0x00   @ 8-bit Huffman, decompressed size 4
    .byte 0x01, 0xC0, 0x41, 0x42   @ tree_size=1, root=0xC0(both children data), A=0x41, B=0x42
    .byte 0x00, 0x00, 0x00, 0x10   @ bitstream MSB-first: 0,0,0,1 -> A,A,A,B
