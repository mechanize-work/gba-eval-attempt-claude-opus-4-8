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
    @ atan2(x=0x100,y=0)
    ldr r0, =0x100
    mov r1, #0
    swi 0x0A0000
    mov r0, r0, lsr #1
    ldr r6, =0x06000000
    strh r0, [r6]
    @ atan2(x=0,y=0x100)
    mov r0, #0
    ldr r1, =0x100
    swi 0x0A0000
    mov r0, r0, lsr #1
    ldr r6, =0x06000000
    strh r0, [r6, #2]
    @ atan2(x=0x100,y=0x100)
    ldr r0, =0x100
    ldr r1, =0x100
    swi 0x0A0000
    mov r0, r0, lsr #1
    ldr r6, =0x06000000
    strh r0, [r6, #4]
    @ atan2(x=-0x100,y=0x100)
    ldr r0, =0xFFFFFF00
    ldr r1, =0x100
    swi 0x0A0000
    mov r0, r0, lsr #1
    ldr r6, =0x06000000
    strh r0, [r6, #6]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
