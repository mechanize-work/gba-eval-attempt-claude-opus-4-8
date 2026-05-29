.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x02000000
    mov r2, #0
tbl:
    lsl r1, r2, #5
    orr r1, r1, r2
    strh r1, [r0], #2
    add r2, r2, #1
    cmp r2, #160
    blt tbl
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r1, =0x0800
    strh r1, [r12, #8]
    ldr r1, =0x0100
    strh r1, [r12]            @ DISPCNT mode0 BG0
loopm:
    @ wait VCOUNT==162
wv: ldrh r1, [r12, #6]
    cmp r1, #162
    bne wv
    ldr r1, =0x02000000
    str r1, [r12, #0xB0]
    ldr r1, =0x05000002
    str r1, [r12, #0xB4]
    ldr r1, =0xA2400001
    str r1, [r12, #0xB8]
ww: ldrh r1, [r12, #6]
    cmp r1, #162
    beq ww
    b loopm
