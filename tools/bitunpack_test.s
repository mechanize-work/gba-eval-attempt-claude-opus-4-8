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
    adr r0, bsrc
    ldr r1, =0x02000000
    adr r2, bhdr
    swi 0x100000               @ BitUnPack
    ldr r0, =0x02000000
    ldr r6, =0x06000000
    ldrh r3, [r0]
    strh r3, [r6]
    ldrh r3, [r0, #2]
    strh r3, [r6, #2]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
.align 2
bsrc:
    .byte 0xB1, 0, 0, 0
bhdr:
    .hword 1                   @ src_length=1 byte
    .byte 1                    @ src_bit_width=1
    .byte 4                    @ dst_bit_width=4
    .word 0                    @ data_offset=0
