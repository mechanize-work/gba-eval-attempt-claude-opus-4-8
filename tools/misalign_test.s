.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r4, =0x03000000
    ldr r5, =0x12345678
    str r5, [r4]
    ldr r0, [r4, #1]          @ misaligned LDR +1 -> ROR8 = 0x78123456
    ldr r1, [r4, #2]          @ +2 -> ROR16 = 0x56781234
    ldr r2, [r4, #3]          @ +3 -> ROR24 = 0x34567812
    add r3, r4, #1
    ldrh r7, [r3]             @ LDRH odd -> [aligned] ROR8 = 0x78000056
    ldr r6, =0x06000000
    strh r0, [r6]
    mov r0, r0, lsr #16
    strh r0, [r6, #2]
    strh r1, [r6, #4]
    mov r1, r1, lsr #16
    strh r1, [r6, #6]
    strh r2, [r6, #8]
    mov r2, r2, lsr #16
    strh r2, [r6, #10]
    strh r7, [r6, #12]
    mov r7, r7, lsr #16
    strh r7, [r6, #14]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
