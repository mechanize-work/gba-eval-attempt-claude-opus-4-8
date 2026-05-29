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
    ldr r1, =0x1077            @ SOUNDCNT_L vol7/7, ch1 LEFT only (bit12, NOT bit8)
    strh r1, [r0, #0x80]
    mov r1, #0
    strh r1, [r0, #0x60]
    ldr r1, =0xF080            @ ch1 duty2 env15
    strh r1, [r0, #0x62]
    ldr r1, =0x8500            @ ch1 freq trigger
    strh r1, [r0, #0x64]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
