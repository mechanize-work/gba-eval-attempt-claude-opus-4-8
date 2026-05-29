.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x001F
    strh r1, [r0, #2]        @ pal[1] red
    ldr r1, =0x7C00
    strh r1, [r0, #4]        @ pal[2] blue
    @ tile0 = vertical stripes (px x -> (x&1)+1): all bytes 0x21
    ldr r0, =0x06000000
    ldr r1, =0x21212121
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ table 0..207 in EWRAM (one BGHOFS per scanline)
    ldr r0, =0x02000000
    mov r2, #0
2:  strh r2, [r0], #2
    add r2, r2, #1
    cmp r2, #208
    blt 2b
    @ BG0CNT screen base 8
    ldr r1, =0x0800
    strh r1, [r12, #8]
    @ DMA0: src=table dst=BG0HOFS(0x4000010) count=1 ctrl=0xA240 (en,HBlank,repeat,dstfixed,16bit,srcinc)
    ldr r1, =0x02000000
    str r1, [r12, #0xB0]
    ldr r1, =0x04000010
    str r1, [r12, #0xB4]
    ldr r1, =0xA2400001
    str r1, [r12, #0xB8]
    ldr r1, =0x0100
    strh r1, [r12]
forever:
    b forever
