.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0
    strh r1, [r12]
    ldr r1, =0x03000010
    mov r8, #0xAA              @ user/SYS r8 = 0xAA
    mrs r0, cpsr
    bic r0, r0, #0x1F
    orr r0, r0, #0x11          @ -> FIQ mode (banks r8-r14)
    msr cpsr_c, r0
    mov r8, #0xBB              @ FIQ r8 = 0xBB
    stmia r1, {r8}^            @ store USER r8 (0xAA), not FIQ r8
    mrs r0, cpsr
    bic r0, r0, #0x1F
    orr r0, r0, #0x1F          @ -> SYS mode
    msr cpsr_c, r0
    ldrh r2, [r1]
    ldr r3, =0x05000000
    strh r2, [r3]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
