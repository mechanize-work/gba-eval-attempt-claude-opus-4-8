.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x05000200
    ldr r2, =0x001F
    strh r2, [r1, #2]
    ldr r2, =0x03E0
    strh r2, [r1, #4]
    ldr r2, =0x7C00
    strh r2, [r1, #6]
    ldr r2, =0x7FFF
    strh r2, [r1, #8]
    ldr r2, =0x03FF
    strh r2, [r1, #10]
    ldr r2, =0x7FE0
    strh r2, [r1, #12]
    ldr r2, =0x7C1F
    strh r2, [r1, #14]
    ldr r2, =0x4210
    strh r2, [r1, #16]
    ldr r1, =0x06010000
    ldr r2, =0x87654321
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 1b
    ldr r1, =0x0300           @ MOSAIC OBJ H=4
    strh r1, [r0, #0x4C]
    ldr r1, =0x07000000
    ldr r2, =0x1028           @ y=40, mosaic, 8x8
    strh r2, [r1]
    ldr r2, =0x1028           @ x=40, hflip(bit12=0x1000), 8x8
    strh r2, [r1, #2]
    mov r2, #0
    strh r2, [r1, #4]
    ldr r1, =0x1040
    strh r1, [r0]
forever:
    b forever
