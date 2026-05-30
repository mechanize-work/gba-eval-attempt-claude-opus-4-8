.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    @ ASR #32 of 0x80000000 -> 0xFFFFFFFF
    ldr r1, =0x80000000
    mov r0, r1, asr #32
    cmn r0, #1               @ Z set if r0 == -1
    bne bad
    @ LSR #32 of 0x80000000 -> 0
    mov r0, r1, lsr #32
    cmp r0, #0
    bne bad
    @ RRX: set C=1 then rrx 0x2 -> 0x80000001
    msr cpsr_f, #0x20000000
    mov r3, #2
    mov r0, r3, rrx
    ldr r1, =0x80000001
    cmp r0, r1
    bne bad
    ldr r1, =0x05000000
    ldr r2, =0x03E0          @ green = all pass
    strh r2, [r1]
    b done
bad:
    ldr r1, =0x05000000
    ldr r2, =0x001F          @ red = fail
    strh r2, [r1]
done:
    ldr r2, =0x04000000
    mov r1, #0
    strh r1, [r2]
forever:
    b forever
    .ltorg
