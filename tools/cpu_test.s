@ CPU edge-case test: compute a checksum of many tricky operations into r10,
@ then write it to palette as colors. Any CPU bug -> different checksum.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r11, =0x04000000
    mov r10, #0              @ checksum accumulator

    @ --- ADD/SUB carry & overflow corners ---
    mov r0, #0x80000000 >> 24
    mov r0, r0, lsl #24      @ r0 = 0x80000000
    adds r1, r0, r0          @ 0x80000000+0x80000000 -> 0, C=1, V=1
    mrs r2, cpsr
    eor r10, r10, r2
    eor r10, r10, r1

    mov r0, #0
    subs r1, r0, #1          @ 0-1 -> 0xFFFFFFFF, C=0(borrow), V=0
    mrs r2, cpsr
    eor r10, r10, r2
    eor r10, r10, r1

    movs r3, #1
    rsbs r1, r3, #0          @ 0-1
    mrs r2, cpsr
    eor r10, r10, r2

    @ ADC/SBC with carry
    msr cpsr_f, #0x20000000  @ set C
    mov r0, #5
    adcs r1, r0, #10         @ 5+10+1=16
    eor r10, r10, r1
    mrs r2, cpsr
    eor r10, r10, r2
    msr cpsr_f, #0           @ clear C
    mov r0, #20
    sbcs r1, r0, #5          @ 20-5-1=14
    eor r10, r10, r1
    mrs r2, cpsr
    eor r10, r10, r2

    @ --- shift edge cases ---
    ldr r0, =0xDEADBEEF
    mov r1, r0, lsr #32 & 0  @ this is just to vary; use explicit
    movs r1, r0, lsr #32     @ LSR #32 (encoded as #0 special)? assembler: lsr #32 valid -> 0, C=bit31
    eor r10, r10, r1
    mrs r2, cpsr
    eor r10, r10, r2
    movs r1, r0, asr #32     @ ASR #32 -> all sign bits
    eor r10, r10, r1
    mrs r2, cpsr
    eor r10, r10, r2
    msr cpsr_f, #0x20000000  @ C=1 for RRX
    movs r1, r0, rrx         @ RRX: rotate right through carry
    eor r10, r10, r1
    mrs r2, cpsr
    eor r10, r10, r2
    movs r1, r0, ror #1
    eor r10, r10, r1
    movs r1, r0, lsl #1
    eor r10, r10, r1
    mrs r2, cpsr
    eor r10, r10, r2

    @ register-specified shift >= 32
    ldr r0, =0x12345678
    mov r4, #40
    movs r1, r0, lsr r4      @ LSR by 40 (>32) -> 0, C=0
    eor r10, r10, r1
    mov r4, #32
    movs r1, r0, lsl r4      @ LSL by 32 -> 0, C=bit0
    eor r10, r10, r1
    mrs r2, cpsr
    eor r10, r10, r2

    @ --- multiply variants ---
    ldr r0, =0xFFFFFFFF      @ -1
    ldr r1, =0x00000010      @ 16
    mul r2, r0, r1           @ -16
    eor r10, r10, r2
    smull r3, r4, r0, r1     @ signed long: -16 -> r3=lo, r4=hi(-1)
    eor r10, r10, r3
    eor r10, r10, r4
    umull r3, r4, r0, r1     @ unsigned long
    eor r10, r10, r3
    eor r10, r10, r4

    @ --- LDM/STM with writeback ---
    ldr r0, =0x02000000
    ldr r5, =0x11112222
    ldr r6, =0x33334444
    ldr r7, =0x55556666
    stmia r0!, {r5,r6,r7}
    ldr r0, =0x02000000
    ldmia r0!, {r1,r2,r3}
    eor r10, r10, r1
    eor r10, r10, r2
    eor r10, r10, r3
    eor r10, r10, r0         @ writeback value

    @ write checksum to palette[0..1] (16 bits each)
    ldr r11, =0x05000000
    strh r10, [r11]
    mov r1, r10, lsr #16
    strh r1, [r11, #2]
    mov r1, #0
    ldr r11, =0x04000000
    strh r1, [r11]           @ DISPCNT=0
forever:
    b forever
