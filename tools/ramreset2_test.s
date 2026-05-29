.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x001F
    strh r1, [r0]              @ palette[0]=red
    mov r0, #0x08
    swi 0x010000               @ RegisterRamReset: clear VRAM only (NOT palette)
    mov r1, #0
    strh r1, [r12]
    ldr r0, =0x05000000
    ldrh r2, [r0]              @ palette[0] after VRAM-only reset
    ldr r3, =0x06000000
    strh r2, [r3]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
