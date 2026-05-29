.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    mov r1, #0x80
    strh r1, [r0, #0x84]       @ master enable
    mov r1, #2
    strh r1, [r0, #0x82]       @ PSG 100%
    ldr r1, =0x2277           @ ch2 L+R, vol 7/7
    strh r1, [r0, #0x80]
    ldr r1, =0xF000           @ ch2: duty 0 (12.5%), env vol 15
    strh r1, [r0, #0x68]
    ldr r1, =0x86D6           @ freq, trigger
    strh r1, [r0, #0x6C]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
