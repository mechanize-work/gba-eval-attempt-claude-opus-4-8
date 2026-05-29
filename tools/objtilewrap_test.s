.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ OBJ palette[2]=green, [3]=blue
    ldr r1, =0x05000200
    ldr r2, =0x03E0
    strh r2, [r1, #4]
    ldr r2, =0x7C00
    strh r2, [r1, #6]
    @ OBJ tiles 0,1 @ 0x06010000 = index 3 (blue)
    ldr r1, =0x06010000
    ldr r2, =0x33333333
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #64
    blt 1b
    @ OBJ tiles 1022,1023 @ 0x06017FC0 = index 2 (green)
    ldr r1, =0x06017FC0
    ldr r2, =0x22222222
    mov r3, #0
2:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #64
    blt 2b
    @ OAM: 32x32 sprite at (40,40), tile 1022
    ldr r1, =0x07000000
    ldr r2, =0x0028           @ y=40, square
    strh r2, [r1]
    ldr r2, =0x8028           @ x=40, size2 (32x32)
    strh r2, [r1, #2]
    ldr r2, =0x03FE           @ tile 1022
    strh r2, [r1, #4]
    ldr r1, =0x1040           @ DISPCNT mode0|OBJ|1D
    strh r1, [r0]
forever:
    b forever
