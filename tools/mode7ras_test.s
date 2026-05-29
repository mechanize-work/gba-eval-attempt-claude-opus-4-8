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
    strh r1, [r0, #2]
    ldr r1, =0x7C00
    strh r1, [r0, #4]
    @ affine tile0 (8bpp)=index1 red, tile1=index2 blue
    ldr r0, =0x06000000
    ldr r1, =0x01010101
    mov r3, #16
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x02020202
    mov r3, #16
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    @ affine map @0x06004000 column-alternating (8px stripes)
    ldr r0, =0x06004000
    ldr r1, =0x01000100
    mov r3, #64
3:  str r1, [r0], #4
    subs r3, r3, #1
    bne 3b
    @ PA table: 0x100 + 8*line
    ldr r0, =0x02000000
    ldr r2, =0x100
    mov r4, #228
4:  strh r2, [r0], #2
    add r2, r2, #8
    subs r4, r4, #1
    bne 4b
    @ BG2CNT screen base 8, size0
    ldr r1, =0x0800
    strh r1, [r12, #0xC]
    @ affine params PA=0x100 PB=0 PC=0 PD=0x100 ref=0
    ldr r1, =0x0100
    strh r1, [r12, #0x20]
    mov r1, #0
    strh r1, [r12, #0x22]
    strh r1, [r12, #0x24]
    ldr r1, =0x0100
    strh r1, [r12, #0x26]
    mov r1, #0
    str r1, [r12, #0x28]
    str r1, [r12, #0x2C]
    @ DMA0 dst = BG2PA (0x4000020)
    ldr r1, =0x04000020
    str r1, [r12, #0xB4]
    ldr r1, =0x0402
    strh r1, [r12]
loop:
5:  ldrh r1, [r12, #6]
    cmp r1, #160
    blt 5b
    mov r1, #0
    str r1, [r12, #0xB8]
    ldr r1, =0x02000000
    str r1, [r12, #0xB0]
    ldr r1, =0xA2400001
    str r1, [r12, #0xB8]
6:  ldrh r1, [r12, #6]
    cmp r1, #160
    bge 6b
    b loop
