.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x02000000
    ldr r1, =0x12348078      @ bytes: 78 80 34 12
    str r1, [r0]
    add r0, r0, #1           @ odd address 0x02000001 (byte 0x80)
    ldrsh r2, [r0]           @ LDRSH-odd -> sign-extended byte 0x80 = 0xFFFFFF80
    ldr r5, =0x7FFF
    and r2, r2, r5
    ldr r1, =0x05000000
    strh r2, [r1]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
