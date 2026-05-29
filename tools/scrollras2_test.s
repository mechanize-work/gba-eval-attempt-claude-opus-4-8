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
    ldr r0, =0x06000000
    ldr r1, =0x21212121
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ table: line N gets BGHOFS = N (0..227)
    ldr r0, =0x02000000
    mov r2, #0
2:  strh r2, [r0], #2
    add r2, r2, #1
    cmp r2, #228
    blt 2b
    ldr r1, =0x0800
    strh r1, [r12, #8]
    ldr r1, =0x04000010
    str r1, [r12, #0xB4]
    ldr r1, =0x0100
    strh r1, [r12]
loop:
    @ wait for VBlank (vcount>=160)
3:  ldrh r1, [r12, #6]
    cmp r1, #160
    blt 3b
    @ re-arm DMA0: disable, reset src, enable
    mov r1, #0
    str r1, [r12, #0xB8]
    ldr r1, =0x02000000
    str r1, [r12, #0xB0]
    ldr r1, =0xA2400001
    str r1, [r12, #0xB8]
    @ wait for visible again
4:  ldrh r1, [r12, #6]
    cmp r1, #160
    bge 4b
    b loop
