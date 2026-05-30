.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    @ SMULL (-3) * 5 = -15 = 0xFFFFFFFF_FFFFFFF1
    mov r0, #0
    sub r0, r0, #3          @ r0 = -3
    mov r1, #5
    smull r2, r3, r0, r1    @ r3=high=0xFFFFFFFF, r2=low=0xFFFFFFF1
    ldr r5, =0xFFFFFFF1
    cmp r2, r5
    bne bad
    cmp r3, #-1            @ high = 0xFFFFFFFF = -1
    bne bad
    @ SMLAL: accumulate. r3:r2 currently -15. SMLAL r2,r3,r0,r1 adds (-3*5)=-15 -> -30
    smlal r2, r3, r0, r1   @ r3:r2 = -15 + (-15) = -30 = 0xFFFFFFFF_FFFFFFE2
    ldr r5, =0xFFFFFFE2
    cmp r2, r5
    bne bad
    cmp r3, #-1
    bne bad
    @ all good -> green
    ldr r1, =0x05000000
    ldr r4, =0x03E0
    strh r4, [r1]
    b done
bad:
    ldr r1, =0x05000000
    ldr r4, =0x001F        @ red = fail
    strh r4, [r1]
done:
    ldr r2, =0x04000000
    mov r1, #0
    strh r1, [r2]
forever:
    b forever
    .ltorg
