.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ palette
    ldr r1, =0x05000000
    ldr r2, =0x7FFF
    strh r2, [r1, #2]          @ color1 white
    @ BG0 4bpp tile 1 = vertical stripe (left 4 px index1, right 0)
    ldr r1, =0x06000020        @ tile 1
    ldr r2, =0x00001111        @ row: px0-3 = index1, px4-7 = 0
    mov r3, #0
ti: str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt ti
    @ BG0 map (screenbase 0x6000800 default sb=1): fill with tile 1
    ldr r1, =0x06000800
    mov r3, #0
    ldr r2, =0x00010001
mp: str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #0x800
    blt mp
    @ BG0CNT: screenbase block 1 (0x100), charbase 0
    mov r1, #0x100
    strh r1, [r0, #8]
    @ HDMA table at 0x02000000: value = line index (0..227)
    ldr r1, =0x02000000
    mov r3, #0
    mov r4, #0
ht: strh r3, [r1, r4]
    add r3, r3, #1
    add r4, r4, #2
    cmp r3, #228
    blt ht
    @ DMA0: src=table, dst=BG0HOFS(0x4000010), count=1, hblank, repeat, 16-bit
    ldr r2, =0x02000000
    str r2, [r0, #0xB0]        @ DMA0 src
    ldr r2, =0x04000010
    str r2, [r0, #0xB4]        @ DMA0 dst
    mov r2, #1
    strh r2, [r0, #0xB8]       @ count 1
    ldr r2, =0xB600            @ enable|repeat|hblank timing(2<<12)|dst fixed... 
    @ control: enable(0x8000)|repeat(0x200)|timing hblank(2<<12=0x2000)|dst incr(0)= 0xA200
    ldr r2, =0xA200
    strh r2, [r0, #0xBA]
    @ DISPCNT: mode 0, BG0 on
    ldr r1, =0x0100
    strh r1, [r0]
forever:
    b forever
