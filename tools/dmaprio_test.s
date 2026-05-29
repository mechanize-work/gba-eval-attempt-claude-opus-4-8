.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r4, =0x03000000
    ldr r1, =0xAAAA
    str r1, [r4]               @ A at 0x03000000
    ldr r1, =0xBBBB
    str r1, [r4, #4]           @ B at 0x03000004
    str r4, [r12, #0xB0]       @ DMA0 src=A
    add r1, r4, #0x10
    str r1, [r12, #0xB4]       @ DMA0 dst=0x03000010
    add r1, r4, #4
    str r1, [r12, #0xBC]       @ DMA1 src=B
    add r1, r4, #0x10
    str r1, [r12, #0xC0]       @ DMA1 dst=0x03000010 (same)
    ldr r1, =0x94000001        @ enable + VBlank + 32bit + count1
    str r1, [r12, #0xC4]       @ enable DMA1 FIRST
    str r1, [r12, #0xB8]       @ then DMA0
    mov r1, #0
    strh r1, [r12]
    ldr r0, =0x05000000
loop:
    ldrh r2, [r4, #0x10]       @ read dest after VBlank DMAs
    strh r2, [r0]
    b loop
