.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r2, =0x7FFFFFFF
    adds r1, r2, #1          @ INT_MAX+1 -> 0x80000000: N=1 Z=0 C=0 V=1
    mrs r5, cpsr
    mov r5, r5, lsr #28

    ldr r2, =0x80000000
    subs r1, r2, #1          @ INT_MIN-1 -> 0x7FFFFFFF: N=0 Z=0 C=1 V=1
    mrs r6, cpsr
    mov r6, r6, lsr #28

    mvn r2, #0               @ 0xFFFFFFFF
    adds r1, r2, #1          @ -1+1 -> 0: N=0 Z=1 C=1 V=0
    mrs r7, cpsr
    mov r7, r7, lsr #28

    orr r5, r5, r6, lsl #4
    orr r5, r5, r7, lsl #8
    ldr r1, =0x7FFF
    and r5, r5, r1
    ldr r1, =0x05000000
    strh r5, [r1]
    ldr r0, =0x04000000
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
