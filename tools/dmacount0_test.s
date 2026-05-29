.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x02000000
    ldr r2, =0x1234
    strh r2, [r1]              @ src value (fixed-read)
    @ DMA0: src fixed=0x02000000, dst inc=0x06000000, count=0 (->0x4000), 16-bit, immediate
    ldr r2, =0x02000000
    str r2, [r0, #0xB0]
    ldr r2, =0x06000000
    str r2, [r0, #0xB4]
    mov r2, #0
    strh r2, [r0, #0xB8]       @ count = 0
    ldr r2, =0x8100           @ enable | src fixed(0x100) | 16-bit | immediate
    strh r2, [r0, #0xBA]
    @ read VRAM at offset 0x3000 (deep into a max transfer)
    ldr r1, =0x06003000
    ldrh r3, [r1]
    ldr r1, =0x7FFF
    and r3, r3, r1
    ldr r1, =0x05000000
    strh r3, [r1]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
