.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ DISPCNT = mode 3, BG2 on (0x0403)
    ldr r1, =0x0403
    strh r1, [r12]
    @ Fill VRAM 0x06000000 with pattern: color = (x ^ y) | ((x*y)<<5)
    ldr r2, =0x06000000
    mov r4, #0                 @ y
yloop:
    mov r5, #0                 @ x
xloop:
    eor r6, r4, r5             @ x ^ y
    add r7, r5, r4
    lsl r7, r7, #5
    eor r6, r6, r7
    ldr r8, =0x7FFF
    and r6, r6, r8             @ 15-bit color
    strh r6, [r2]
    add r2, r2, #2
    add r5, r5, #1
    cmp r5, #240
    blt xloop
    add r4, r4, #1
    cmp r4, #160
    blt yloop
forever:
    b forever
