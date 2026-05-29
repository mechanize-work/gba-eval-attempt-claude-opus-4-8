.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r0, #0
    strh r0, [r12]            @ DISPCNT=0 FIRST
    @ src @ 0x02000000: RLE header + data
    @ header word: type3(0x30) | size6 -> 0x00000630
    ldr r1, =0x02000000
    ldr r2, =0x00000630
    str r2, [r1]
    @ RLE data: 0x81,0xAA (run of 4 AA), 0x01,0xBB,0xCC (literal BB,CC)
    mov r2, #0x81
    strb r2, [r1, #4]
    mov r2, #0xAA
    strb r2, [r1, #5]
    mov r2, #0x01
    strb r2, [r1, #6]
    mov r2, #0xBB
    strb r2, [r1, #7]
    mov r2, #0xCC
    strb r2, [r1, #8]
    @ RLUnCompVram: r0=src, r1=dest(VRAM)
    ldr r0, =0x02000000
    ldr r1, =0x06000000
    swi 0x150000
    @ read VRAM[0] (0xAAAA) and VRAM[4] (0xCCBB)
    ldr r1, =0x06000000
    ldrh r3, [r1, #0]
    ldrh r4, [r1, #4]
    eor r3, r3, r4
    ldr r1, =0x7FFF
    and r3, r3, r1
    ldr r1, =0x05000000
    strh r3, [r1]
forever:
    b forever
