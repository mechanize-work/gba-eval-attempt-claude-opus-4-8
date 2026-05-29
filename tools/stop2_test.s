.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r10, =0x04000132
    ldr r1, =0x4001            @ KEYCNT: A mask + IRQ enable
    strh r1, [r10]
    ldr r10, =0x04000200
    ldr r1, =0x1000            @ IE = keypad (bit12)
    strh r1, [r10]
    ldr r0, =0x05000000
    ldr r1, =0x001F
    strh r1, [r0]              @ backdrop red
    mov r1, #0
    strh r1, [r12]
    ldr r10, =0x04000301
    mov r1, #0x80
    strb r1, [r10]             @ STOP (wake source = keypad, but no key pressed)
    ldr r1, =0x03E0
    strh r1, [r0]              @ green (runs only if NOT halted)
forever:
    b forever
