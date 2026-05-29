@ Unaligned LDR/LDRH rotate (ARMv4): word 0x11223344 read at +1/+2/+3 rotates;
@ LDRH at odd addr rotates by 8. XOR results into backdrop; compare vs oracle.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4

main:
    ldr r1, =0x02000000
    ldr r2, =0x11223344
    str r2, [r1]

    ldr r3, [r1, #1]          @ ROR8  -> 0x44112233
    ldr r4, [r1, #2]          @ ROR16 -> 0x33441122
    ldr r5, [r1, #3]          @ ROR24 -> 0x22334411
    ldrh r6, [r1, #1]         @ LDRH odd -> ROR8(0x3344) = 0x44000033
    ldrh r7, [r1, #2]         @ LDRH aligned -> 0x00001122

    eor r3, r3, r4
    eor r3, r3, r5
    eor r3, r3, r6
    eor r3, r3, r7
    ldr r1, =0x7FFF
    and r3, r3, r1
    ldr r1, =0x05000000
    strh r3, [r1]
    ldr r0, =0x04000000
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
