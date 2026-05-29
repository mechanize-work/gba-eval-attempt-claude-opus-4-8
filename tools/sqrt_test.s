.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0
    strh r1, [r12]            @ DISPCNT=0 first (no forced-blank confound)
    ldr r0, =100
    swi 0x080000
    mov r8, r0               @ sqrt(100)=10
    ldr r0, =65536
    swi 0x080000
    mov r9, r0               @ sqrt(65536)=256
    ldr r0, =123456
    swi 0x080000
    mov r10, r0             @ sqrt(123456)=351
    ldr r0, =0x3FFFFFFF
    swi 0x080000
    mov r7, r0              @ sqrt(0x3FFFFFFF)=46340
    ldr r6, =0x06000000
    strh r8, [r6]
    strh r9, [r6, #2]
    strh r10, [r6, #4]
    strh r7, [r6, #6]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
