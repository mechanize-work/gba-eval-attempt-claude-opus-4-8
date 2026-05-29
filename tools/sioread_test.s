@ SIO register readback: write RCNT (0x134) + SIOCNT (0x128), read back.
@ mine has no SIO handler (returns open-bus); compare to oracle's stored values.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4

main:
    ldr r0, =0x04000000
    ldr r5, =0x04000128        @ SIOCNT
    ldr r6, =0x04000134        @ RCNT

    ldr r1, =0x1234            @ no start bit (bit7=0)
    strh r1, [r5]
    ldr r1, =0x4321
    strh r1, [r6]

    ldrh r3, [r5]             @ read SIOCNT
    ldrh r4, [r6]             @ read RCNT

    eor r3, r3, r4
    ldr r1, =0x7FFF
    and r3, r3, r1
    ldr r1, =0x05000000
    strh r3, [r1]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
