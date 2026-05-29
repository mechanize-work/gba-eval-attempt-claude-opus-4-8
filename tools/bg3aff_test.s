.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ palette[2] = green
    ldr r1, =0x05000000
    ldr r2, =0x03E0
    strh r2, [r1, #4]
    @ 8bpp tile1 @ 0x06000040 = index 2
    ldr r1, =0x06000040
    ldr r2, =0x02020202
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #64
    blt 1b
    @ affine map @ 0x06004000 (block 8), 16x16 all tile 1
    ldr r1, =0x06004000
    mov r4, #1
    mov r3, #0
2:  strb r4, [r1, r3]
    add r3, r3, #1
    cmp r3, #256
    blt 2b
    @ BG3CNT @ 0x0E: screenbase block 8
    ldr r1, =0x0800
    strh r1, [r0, #0x0E]
    @ BG3 identity matrix
    mov r1, #0x100
    strh r1, [r0, #0x30]      @ BG3PA
    mov r1, #0
    strh r1, [r0, #0x32]
    strh r1, [r0, #0x34]
    mov r1, #0x100
    strh r1, [r0, #0x36]      @ BG3PD
    mov r1, #0
    str r1, [r0, #0x38]       @ BG3X
    str r1, [r0, #0x3C]       @ BG3Y
    @ DISPCNT mode2 | BG3
    ldr r1, =0x0802
    strh r1, [r0]
forever:
    b forever
