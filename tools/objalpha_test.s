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
    strh r1, [r0]
    ldr r0, =0x05000202
    ldr r1, =0x4210
    strh r1, [r0]
    ldr r0, =0x06000020
    ldr r1, =0x11111111
    mov r2, #8
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b
    ldr r0, =0x06004000
    ldr r1, =0x00010001
    mov r2, #512
2:  str r1, [r0], #4
    subs r2, r2, #1
    bne 2b
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r2, #8
3:  str r1, [r0], #4
    subs r2, r2, #1
    bne 3b
    ldr r1, =0x0800
    strh r1, [r12, #0x08]
    ldr r0, =0x07000000
    ldr r1, =0x0050
    strh r1, [r0]
    ldr r1, =0x0050
    strh r1, [r0, #2]
    mov r1, #0
    strh r1, [r0, #4]
    ldr r1, =0x0150
    strh r1, [r12, #0x50]      @ BLDCNT mode1 + OBJ 1st + BG0 2nd
    ldr r1, =0x0808
    strh r1, [r12, #0x52]      @ BLDALPHA EVA=8 EVB=8
    ldr r1, =0x1140
    strh r1, [r12]
forever:
    b forever
