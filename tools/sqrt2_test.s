.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0
    strh r1, [r12]
    ldr r0, =100
    swi 0x080000
    ldr r6, =0x06000000
    strh r0, [r6]
    ldr r0, =65536
    swi 0x080000
    ldr r6, =0x06000000
    strh r0, [r6, #2]
    ldr r0, =123456
    swi 0x080000
    ldr r6, =0x06000000
    strh r0, [r6, #4]
    ldr r0, =1000000
    swi 0x080000
    ldr r6, =0x06000000
    strh r0, [r6, #6]
    ldr r0, =2
    swi 0x080000
    ldr r6, =0x06000000
    strh r0, [r6, #8]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
