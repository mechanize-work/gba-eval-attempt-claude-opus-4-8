.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000002
    ldr r1, =0x001F
    strh r1, [r0]              @ pal[1]=red
    ldr r1, =0x03E0
    strh r1, [r0, #2]          @ pal[2]=green
    ldr r0, =0x06000000        @ frame 0
    ldr r1, =0x01010101
    mov r2, #9600
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b
    ldr r0, =0x0600A000        @ frame 1
    ldr r1, =0x02020202
    mov r2, #9600
2:  str r1, [r0], #4
    subs r2, r2, #1
    bne 2b
    ldr r1, =0x0414            @ mode4 + BG2 + frame-select(bit4)
    strh r1, [r12]
forever:
    b forever
