.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0x80
    strh r1, [r12, #0x84]
    ldr r1, =0x2277
    strh r1, [r12, #0x80]
    mov r1, #2
    strh r1, [r12, #0x82]
    @ ch2: duty 50%, vol 15, freq=1024 (square 131072/(2048-1024)=128Hz)
    ldr r1, =0xF080
    strh r1, [r12, #0x68]
    ldr r1, =0x8400
    strh r1, [r12, #0x6C]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
