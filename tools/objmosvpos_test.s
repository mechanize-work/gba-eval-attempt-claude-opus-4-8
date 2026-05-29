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
    @ OBJ tile0: row r = index r+1
    ldr r1, =0x06010000
    ldr r2, =0x11111111
    str r2, [r1, #0]
    ldr r2, =0x22222222
    str r2, [r1, #4]
    ldr r2, =0x33333333
    str r2, [r1, #8]
    ldr r2, =0x44444444
    str r2, [r1, #12]
    ldr r2, =0x55555555
    str r2, [r1, #16]
    ldr r2, =0x66666666
    str r2, [r1, #20]
    ldr r2, =0x77777777
    str r2, [r1, #24]
    ldr r2, =0x88888888
    str r2, [r1, #28]
    mov r1, #0x3000
    strh r1, [r0, #0x4C]       @ MOSAIC V=4
    ldr r1, =0x07000000
    ldr r2, =0x102A           @ y=42, mosaic, 8x8
    strh r2, [r1]
    mov r2, #40               @ x=40 (block-aligned, clean horizontal)
    strh r2, [r1, #2]
    mov r2, #0
    strh r2, [r1, #4]
    ldr r1, =0x1040
    strh r1, [r0]
forever:
    b forever
