.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x80000001
    mov r2, #0              @ result accumulator
    mov r6, #0              @ carry accumulator
    @ LSR #32 (imm special)
    movs r1, r0, lsr #32
    eor r2, r2, r1
    adc r6, r6, #0
    @ ASR #32 (imm special)
    movs r1, r0, asr #32
    eor r2, r2, r1
    adc r6, r6, #0
    @ RRX (ror #0): set C=1 first via lsr#1 of odd value, then rrx
    movs r4, r0, lsr #1    @ C = bit0 = 1
    movs r1, r0, rrx       @ r1 = (r0>>1)|(C<<31), C=bit0
    eor r2, r2, r1
    adc r6, r6, #0
    @ register shifts
    mov r3, #32
    movs r1, r0, lsl r3    @ LSL 32: 0, C=bit0=1
    eor r2, r2, r1
    adc r6, r6, #0
    movs r1, r0, lsr r3    @ LSR 32: 0, C=bit31=1
    eor r2, r2, r1
    adc r6, r6, #0
    movs r1, r0, ror r3    @ ROR 32: r0, C=bit31=1
    eor r2, r2, r1
    adc r6, r6, #0
    mov r3, #33
    movs r1, r0, lsl r3    @ LSL 33: 0, C=0
    eor r2, r2, r1
    adc r6, r6, #0
    movs r1, r0, asr r3    @ ASR 33: sign, C=sign=1
    eor r2, r2, r1
    adc r6, r6, #0
    @ combine
    eor r2, r2, r6
    ldr r5, =0x7FFF
    and r2, r2, r5
    ldr r1, =0x05000000
    strh r2, [r1]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
