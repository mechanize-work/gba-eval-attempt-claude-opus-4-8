.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r4, =0x0400012A        @ SIODATA8 (normal 8-bit send/recv)
    ldr r5, =0x04000128        @ SIOCNT
    mov r1, #0x55
    strh r1, [r4]              @ SIODATA8 = 0x55 (data to send)
    ldr r1, =0x0081           @ internal clock + start, normal 8-bit
    strh r1, [r5]
    ldr r2, =1500
1:  subs r2, r2, #1
    bne 1b
    ldrh r3, [r4]             @ read received SIODATA8
    ldr r1, =0x7FFF
    and r3, r3, r1
    ldr r1, =0x05000000
    strh r3, [r1]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
