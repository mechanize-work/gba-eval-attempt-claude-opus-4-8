.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r4, =0x02000000
    ldrh r5, [r4]              @ counter (EWRAM persists across SoftReset)
    add r5, r5, #1
    strh r5, [r4]
    cmp r5, #2
    bge done
    ldr r0, =0x03007FFA
    mov r1, #0
    strb r1, [r0]              @ SoftReset flag=0 -> jump to ROM 0x08000000
    swi 0x000000               @ SoftReset
    b forever
done:
    ldr r0, =0x05000000
    ldr r1, =0x03E0            @ green = restart happened (counter reached 2)
    strh r1, [r0]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
