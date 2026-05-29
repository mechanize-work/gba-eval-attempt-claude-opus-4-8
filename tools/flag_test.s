.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r6, #0
    @ Case 1: ADC 0x7FFFFFFF + 0, C=1 -> 0x80000000 (V=1,N=1,C=0)
    msr cpsr_f, #0x20000000
    ldr r0, =0x7FFFFFFF
    adcs r3, r0, #0
    eor r6, r6, r3
    mrs r1, cpsr
    eor r6, r6, r1, lsr #28
    ror r6, r6, #4
    @ Case 2: ADC 0xFFFFFFFF + 0, C=1 -> 0 (C=1,Z=1)
    msr cpsr_f, #0x20000000
    ldr r0, =0xFFFFFFFF
    adcs r3, r0, #0
    eor r6, r6, r3
    mrs r1, cpsr
    eor r6, r6, r1, lsr #28
    ror r6, r6, #4
    @ Case 3: SBC 0x80000000 - 1, C=1 (no borrow) -> 0x7FFFFFFF (V=1,C=1)
    msr cpsr_f, #0x20000000
    ldr r0, =0x80000000
    sbcs r3, r0, #1
    eor r6, r6, r3
    mrs r1, cpsr
    eor r6, r6, r1, lsr #28
    ror r6, r6, #4
    @ Case 4: SBC 0 - 0, C=0 (borrow) -> 0xFFFFFFFF (C=0,N=1)
    msr cpsr_f, #0x00000000
    mov r0, #0
    sbcs r3, r0, #0
    eor r6, r6, r3
    mrs r1, cpsr
    eor r6, r6, r1, lsr #28
    ror r6, r6, #4
    @ Case 5: RSC 1 - 0x80000000 reversed, C=1 -> 1 - 0x80000000 = 0x80000001 (operand2=1,rn... ) 
    msr cpsr_f, #0x20000000
    ldr r0, =0x80000000
    rscs r3, r0, #1        @ r3 = 1 - r0 - !C = 1 - 0x80000000 = 0x80000001
    eor r6, r6, r3
    mrs r1, cpsr
    eor r6, r6, r1, lsr #28
    ror r6, r6, #4
    @ Case 6: ADC 0xFFFFFFFF + 0xFFFFFFFF, C=1
    msr cpsr_f, #0x20000000
    ldr r0, =0xFFFFFFFF
    adcs r3, r0, r0
    eor r6, r6, r3
    mrs r1, cpsr
    eor r6, r6, r1, lsr #28
    ror r6, r6, #4
    ldr r5, =0x7FFF
    and r6, r6, r5
    ldr r1, =0x05000000
    strh r6, [r1]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
