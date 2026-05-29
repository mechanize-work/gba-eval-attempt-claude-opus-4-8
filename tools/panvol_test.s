.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    mov r1, #0x80
    strh r1, [r0, #0x84]
    mov r1, #2
    strh r1, [r0, #0x82]
    ldr r1, =0x1172            @ L vol=7, R vol=2, ch1 both sides
    strh r1, [r0, #0x80]
    mov r1, #0
    strh r1, [r0, #0x60]
    ldr r1, =0xF080
    strh r1, [r0, #0x62]
    ldr r1, =0x8500
    strh r1, [r0, #0x64]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
