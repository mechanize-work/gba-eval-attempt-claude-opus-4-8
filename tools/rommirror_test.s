.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x08000000
    ldr r6, [r1]              @ ROM via WS0
    ldr r1, =0x0A000000
    ldr r7, [r1]              @ ROM via WS1
    ldr r1, =0x0C000000
    ldr r8, [r1]              @ ROM via WS2
    @ green if all three equal, else red
    ldr r2, =0x001F           @ red default
    cmp r6, r7
    bne show
    cmp r7, r8
    bne show
    ldr r2, =0x03E0           @ green
show:
    ldr r1, =0x05000000
    strh r2, [r1]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
