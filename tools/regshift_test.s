.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r1, =0xFFFFFFFF
    mov r2, #0
    mov r0, r1, lsr r2       @ reg LSR by 0 -> UNCHANGED (key: differs from imm LSR#0=LSR32)
    cmn r0, #1
    bne bad
    mov r2, #32
    mov r0, r1, lsr r2       @ reg LSR by 32 -> 0
    cmp r0, #0
    bne bad
    mov r2, #33
    mov r0, r1, lsr r2       @ reg LSR by 33 -> 0
    cmp r0, #0
    bne bad
    mov r2, #200
    mov r0, r1, asr r2       @ reg ASR by 200 (>=32, neg) -> 0xFFFFFFFF
    cmn r0, #1
    bne bad
    ldr r1, =0x12345678
    mov r2, #32
    mov r0, r1, ror r2       @ reg ROR by 32 -> UNCHANGED
    ldr r3, =0x12345678
    cmp r0, r3
    bne bad
    ldr r1, =0x05000000
    ldr r2, =0x03E0
    strh r2, [r1]
    b done
bad:
    ldr r1, =0x05000000
    ldr r2, =0x001F
    strh r2, [r1]
done:
    ldr r2, =0x04000000
    mov r1, #0
    strh r1, [r2]
forever:
    b forever
    .ltorg
