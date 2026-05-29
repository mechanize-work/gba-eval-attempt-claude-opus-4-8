.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    adr r0, rledata
    ldr r1, =0x02000000
    swi 0x140000          @ RLUnCompWram (SWI 0x14)
    ldr r0, =0x02000000
    ldrh r2, [r0, #4]     @ [4] should be 'B','B' = 0x4242
    ldr r3, =0x05000000
    strh r2, [r3]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
.align 2
rledata:
    .byte 0x30, 0x08, 0x00, 0x00
    .byte 0x81, 0x41, 0x81, 0x42   @ 4xA, 4xB
