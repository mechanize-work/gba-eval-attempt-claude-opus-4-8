.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x05000000
    ldr r2, =0x001F           @ backdrop palette[0] = red
    strh r2, [r1]
    @ bitmap (0x06000000) stays all 0x0000 (VRAM inits to 0)
    @ BG2 identity affine
    mov r1, #0x100
    strh r1, [r0, #0x20]      @ PA
    mov r1, #0
    strh r1, [r0, #0x22]
    strh r1, [r0, #0x24]
    mov r1, #0x100
    strh r1, [r0, #0x26]      @ PD
    mov r1, #0
    str r1, [r0, #0x28]
    str r1, [r0, #0x2C]
    ldr r1, =0x0403           @ mode 3 | BG2
    strh r1, [r0]
forever:
    b forever
