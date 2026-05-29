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
    swi 0x130000
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
.align 2
huffdata:
    .byte 0x28, 0x04, 0x00, 0x00   @ 8-bit Huffman, size 4
    .byte 0x03, 0x80, 0x41, 0xC0, 0x42, 0x43, 0x00, 0x00  @ tree: sz=3, root=0x80(L=A data,R=node), A, node1=0xC0(L=B,R=C), B, C, pad
    .byte 0x00, 0x00, 0x00, 0x5E   @ bitstream: 0,10,11,11 = A,B,C,C
