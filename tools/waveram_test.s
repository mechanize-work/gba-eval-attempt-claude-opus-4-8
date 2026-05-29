.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0x80
    strh r1, [r12, #0x84]      @ master enable
    ldr r0, =0x04000090
    mov r1, #0
    strh r1, [r12, #0x70]      @ SOUND3CNT_L bit6=0 (access bank1)
    ldr r1, =0xAAAAAAAA
    str r1, [r0]               @ bank1 = AA
    mov r1, #0x40
    strh r1, [r12, #0x70]      @ bit6=1 (access bank0)
    ldr r1, =0xBBBBBBBB
    str r1, [r0]               @ bank0 = BB
    ldrh r3, [r0]              @ read (bit6=1 -> bank0) = 0xBBBB
    ldr r6, =0x06000000
    strh r3, [r6]
    mov r1, #0
    strh r1, [r12, #0x70]      @ bit6=0 (access bank1)
    ldrh r3, [r0]              @ read = 0xAAAA
    strh r3, [r6, #2]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
