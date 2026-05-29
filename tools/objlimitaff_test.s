.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000200
    ldr r1, =0x001F
    strh r1, [r0, #2]
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    ldr r3, =512
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r0, =0x07000000
    mov r4, #0
2:  ldr r1, =0x0150          @ attr0 Y=80 + affine(mode1)
    strh r1, [r0]
    cmp r4, #NDUM
    movlt r2, #0
    movge r2, #120
    ldr r1, =0xC000          @ size3 + affine idx0 (bits9-13=0)
    orr r1, r1, r2
    strh r1, [r0, #2]
    mov r1, #0
    strh r1, [r0, #4]
    add r0, r0, #8
    add r4, r4, #1
    cmp r4, #NTOT
    blt 2b
    @ affine group0 = identity (PA@0x06=0x100, PB@0x0E=0, PC@0x16=0, PD@0x1E=0x100)
    ldr r0, =0x07000000
    ldr r1, =0x0100
    strh r1, [r0, #0x06]
    mov r1, #0
    strh r1, [r0, #0x0E]
    strh r1, [r0, #0x16]
    ldr r1, =0x0100
    strh r1, [r0, #0x1E]
    ldr r1, =0x1040
    strh r1, [r12]
forever:
    b forever
