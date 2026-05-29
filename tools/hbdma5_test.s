.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ table: red,green,blue repeating x60 = 180 entries
    ldr r0, =0x02000000
    mov r2, #0
tbl:
    ldr r1, =0x001F            @ red
    strh r1, [r0], #2
    ldr r1, =0x03E0            @ green
    strh r1, [r0], #2
    ldr r1, =0x7C00            @ blue
    strh r1, [r0], #2
    add r2, r2, #1
    cmp r2, #60
    blt tbl
    @ BG tile0 = index1
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x0800
    strh r1, [r12, #8]
    @ DMA0 src=table(inc), dst=palette[1](fixed), count=1, hblank, repeat
    ldr r1, =0x02000000
    str r1, [r12, #0xB0]
    ldr r1, =0x05000002
    str r1, [r12, #0xB4]
    ldr r1, =0xA2400001        @ srcinc dstfixed hblank repeat enable
    str r1, [r12, #0xB8]
    ldr r1, =0x0100
    strh r1, [r12]
forever:
    b forever
