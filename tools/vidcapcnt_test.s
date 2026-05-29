.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r4, =0x03000000
    mov r2, #0
    mov r3, #0
1:  str r2, [r4, r3, lsl #2]   @ src[k]=k
    add r2, r2, #1
    add r3, r3, #1
    cmp r3, #256
    blt 1b
    str r4, [r12, #0xD4]
    ldr r5, =0x02000100
    str r5, [r12, #0xD8]
    ldr r1, =0xB6400001        @ enable+special+repeat+32bit+dst-FIXED+count1
    str r1, [r12, #0xDC]
    mov r1, #0
    strh r1, [r12]
    ldr r0, =0x06000000
loop:
    ldrh r2, [r5]              @ dst = last transferred value = count-1
    strh r2, [r0]
    ldr r1, =0x0403
    strh r1, [r12]
    b loop
