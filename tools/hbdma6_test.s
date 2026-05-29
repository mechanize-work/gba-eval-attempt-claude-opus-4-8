.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ table: 180 entries all green (0x03E0)
    ldr r0, =0x02000000
    ldr r1, =0x03E0
    mov r2, #0
tbl:
    strh r1, [r0], #2
    add r2, r2, #1
    cmp r2, #180
    blt tbl
    @ BG tile0 = index1
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ palette[1] = RED initially
    ldr r0, =0x05000002
    ldr r1, =0x001F
    strh r1, [r0]
    ldr r1, =0x0800
    strh r1, [r12, #8]
    @ DMA0 src=table(inc) dst=palette[1](fixed) count=1 hblank repeat
    ldr r1, =0x02000000
    str r1, [r12, #0xB0]
    ldr r1, =0x05000002
    str r1, [r12, #0xB4]
    ldr r1, =0xA2400001
    str r1, [r12, #0xB8]
    ldr r1, =0x0100
    strh r1, [r12]
forever:
    b forever
