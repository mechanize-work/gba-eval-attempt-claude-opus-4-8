.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    @ copy iwloop..iwend to IWRAM 0x03000000
    ldr r0, =iwloop
    ldr r1, =0x03000000
    ldr r2, =iwend
cp: ldr r3, [r0], #4
    str r3, [r1], #4
    cmp r0, r2
    blt cp
    ldr r0, =500000        @ count
    ldr r4, =finish        @ return addr (ROM)
    ldr r3, =0x03000000
    bx r3                  @ jump into IWRAM
iwloop:
    subs r0, r0, #1
    bne iwloop            @ PC-relative -> stays in IWRAM
    bx r4
iwend:
finish:
    ldr r12, =0x04000000
    ldr r2, =0x05000000
    ldr r1, =0x001F
    strh r1, [r2]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
