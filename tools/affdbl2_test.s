.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r1, =0x05000200
    ldr r2, =0x03E0
    strh r2, [r1, #2]        @ OBJ idx1 green
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r3, #0
tf: str r1, [r0], #4
    add r3, r3, #1
    cmp r3, #32
    blt tf
    @ OAM matrix0 identity
    ldr r0, =0x07000006
    ldr r1, =0x0100
    strh r1, [r0]            @ PA
    ldr r0, =0x0700000E
    mov r1, #0
    strh r1, [r0]            @ PB
    ldr r0, =0x07000016
    mov r1, #0
    strh r1, [r0]            @ PC
    ldr r0, =0x0700001E
    ldr r1, =0x0100
    strh r1, [r0]            @ PD
    @ OAM0: Y=50 + rotscale(0x100) + double(0x200) = 0x0332
    ldr r0, =0x07000000
    ldr r1, =0x0332
    strh r1, [r0]
    ldr r1, =0x4032         @ X=50, size1(16x16), affidx0
    strh r1, [r0, #2]
    mov r1, #0
    strh r1, [r0, #4]
    ldr r1, =0x05000000
    mov r2, #0
    strh r2, [r1]           @ backdrop black
    ldr r2, =0x04000000
    ldr r1, =0x1040
    strh r1, [r2]
forever:
    b forever
    .ltorg
