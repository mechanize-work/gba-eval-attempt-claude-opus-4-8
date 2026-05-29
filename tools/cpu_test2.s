@ CPU test 2: SWP, LDM/STM rn-in-list quirks, conditionals, MSR masks.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r10, =0           @ checksum
    ldr r11, =0x02000000  @ scratch RAM

    @ --- SWP ---
    ldr r0, =0xCAFEBABE
    str r0, [r11]
    ldr r1, =0x12345678
    swp r2, r1, [r11]     @ r2 = old mem (0xCAFEBABE), mem = r1
    eor r10, r10, r2
    ldr r3, [r11]
    eor r10, r10, r3      @ should be 0x12345678
    @ SWPB
    ldr r0, =0xAABBCCDD
    str r0, [r11]
    mov r1, #0x99
    swpb r2, r1, [r11]
    eor r10, r10, r2
    ldrb r3, [r11]
    eor r10, r10, r3

    @ --- STM with rn in list, writeback (rn not first) ---
    ldr r0, =0x02000100
    mov r1, #0x11
    mov r2, #0x22
    stmia r0!, {r0-r3}   @ stores r0,r1,r2,r3 with writeback; r0 stored = original
    ldr r4, =0x02000100
    ldmia r4, {r5,r6,r7,r8}
    eor r10, r10, r5     @ stored r0 (original base 0x02000100)
    eor r10, r10, r6
    eor r10, r10, r0     @ writeback value

    @ --- LDM with rn in list (no writeback to rn) ---
    ldr r0, =0x02000200
    ldr r1, =0xDEAD0001
    ldr r2, =0xDEAD0002
    stmia r0, {r1, r2}
    ldr r0, =0x02000200
    ldmia r0, {r0, r3}   @ r0 loaded from mem (overwrites base)
    eor r10, r10, r0
    eor r10, r10, r3

    @ --- conditional execution (all codes via flags) ---
    movs r0, #0          @ Z=1
    moveq r1, #0xE0
    movne r1, #0xFF
    eor r10, r10, r1     @ should be 0xE0
    movs r0, #5          @ Z=0,N=0
    movmi r1, #1
    movpl r1, #0xA5
    eor r10, r10, r1     @ should be 0xA5

    @ --- MSR field mask (set/clear flags) ---
    msr cpsr_f, #0xF0000000   @ set N,Z,C,V
    mrs r0, cpsr
    eor r10, r10, r0
    msr cpsr_f, #0
    mrs r0, cpsr
    eor r10, r10, r0

    @ write checksum to palette
    ldr r11, =0x05000000
    strh r10, [r11]
    mov r1, r10, lsr #16
    strh r1, [r11, #2]
    mov r1, #0
    ldr r11, =0x04000000
    strh r1, [r11]
forever:
    b forever
