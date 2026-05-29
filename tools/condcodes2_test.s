.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r5, =0x90000000       @ NZCV = 1010 (N=1,Z=0,C=1,V=0)
    msr cpsr_f, r5
    mov r4, #0
    orreq r4, r4, #(1<<0)
    orrne r4, r4, #(1<<1)
    orrcs r4, r4, #(1<<2)
    orrcc r4, r4, #(1<<3)
    orrmi r4, r4, #(1<<4)
    orrpl r4, r4, #(1<<5)
    orrvs r4, r4, #(1<<6)
    orrvc r4, r4, #(1<<7)
    orrhi r4, r4, #(1<<8)
    orrls r4, r4, #(1<<9)
    orrge r4, r4, #(1<<10)
    orrlt r4, r4, #(1<<11)
    orrgt r4, r4, #(1<<12)
    orrle r4, r4, #(1<<13)
    orr   r4, r4, #(1<<14)
    ldr r1, =0x7FFF
    and r4, r4, r1
    ldr r1, =0x05000000
    strh r4, [r1]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
