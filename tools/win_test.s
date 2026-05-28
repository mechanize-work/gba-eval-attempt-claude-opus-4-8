.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x05000000
    ldr r2, =0x03FF          @ yellow-ish
    strh r2, [r1, #2]
    @ mode 4 fill index 1
    ldr r1, =0x06000000
    mov r3, #0
    ldr r5, =0x9600
    ldr r2, =0x0101
fv:
    strh r2, [r1, r3]
    add r3, r3, #2
    cmp r3, r5
    blt fv
    @ WIN0H (0x40): x1=60 (left), x2=180 (right) -> (60<<8)|180
    ldr r1, =0x3CB4
    strh r1, [r0, #0x40]
    @ WIN0V (0x44): y1=40, y2=120 -> (40<<8)|120
    ldr r1, =0x2878
    strh r1, [r0, #0x44]
    @ WININ (0x48): win0 enables BG2 (bit2) = 0x04
    mov r1, #4
    strh r1, [r0, #0x48]
    @ WINOUT (0x4A): outside disables all = 0
    mov r1, #0
    strh r1, [r0, #0x4A]
    @ DISPCNT: mode 4, BG2 on, WIN0 on (bit13)
    ldr r1, =0x2404
    strh r1, [r0]
forever:
    b forever
