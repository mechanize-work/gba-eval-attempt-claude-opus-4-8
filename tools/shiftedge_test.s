@ ARM barrel-shifter edge cases: LSR#0(=32), ASR#0(=32), RRX, LSL#0.
@ XOR all results + captured carries into the backdrop color; compare vs oracle.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4

main:
    ldr r1, =0x80000001

    movs r0, r1, lsr #0        @ LSR#32 -> r0=0, C=bit31=1
    mov r5, #0
    adc r5, r5, #0             @ r5 = C

    movs r2, r1, asr #0        @ ASR#32 -> r2=0xFFFFFFFF, C=1
    mov r6, #0
    adc r6, r6, #0

    lsrs r7, r1, #2            @ C = bit1 of r1 = 0 (set carry-in for RRX)
    movs r3, r1, rrx           @ RRX -> r3 = 0x40000000, C = bit0 = 1
    mov r8, #0
    adc r8, r8, #0

    movs r4, r1, lsl #0        @ LSL#0 -> r4 = r1 unchanged, C unchanged

    @ also register-shift >=32: LSR by 32 and 40
    mov r9, #32
    movs r10, r1, lsr r9       @ LSR reg 32 -> 0, C=bit31=1
    mov r11, #0
    adc r11, r11, #0

    @ fold everything
    eor r0, r0, r2
    eor r0, r0, r3
    eor r0, r0, r4
    eor r0, r0, r5
    eor r0, r0, r6
    eor r0, r0, r8
    eor r0, r0, r10
    eor r0, r0, r11
    ldr r1, =0x7FFF
    and r0, r0, r1
    ldr r1, =0x05000000
    strh r0, [r1]

    ldr r0, =0x04000000
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
