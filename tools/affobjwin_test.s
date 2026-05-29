.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ BG palette[1] = green
    ldr r0, =0x05000000
    ldr r1, =0x03E0
    strh r1, [r0, #2]
    @ BG0 tile0 = index1, map all tile0
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r0, =0x06004000
    mov r4, #0
    mov r3, #0
2:  strh r4, [r0, r3]
    add r3, r3, #2
    cmp r3, #2048
    blt 2b
    ldr r1, =0x0800
    strh r1, [r12, #8]          @ BG0CNT screenbase block8
    @ OBJ tiles 0-15 (32x32) = index1 (opaque, marks objwin)
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    ldr r3, =128
3:  str r1, [r0], #4
    subs r3, r3, #1
    bne 3b
    @ OAM[0]: affine(0x100) mode2 objwin(0x800) 32x32 at (60,40), matrix0
    ldr r0, =0x07000000
    ldr r1, =0x093C            @ y=60, affine+objwin
    strh r1, [r0]
    ldr r1, =0x803C            @ x=60, size2
    strh r1, [r0, #2]
    mov r1, #0
    strh r1, [r0, #4]
    @ matrix group0: 45deg rotation PA=PB=0xB5, PC=-0xB5, PD=0xB5
    ldr r1, =0x00B5
    strh r1, [r0, #0x06]       @ PA
    ldr r1, =0x00B5
    strh r1, [r0, #0x0E]       @ PB
    ldr r1, =0xFF4B
    strh r1, [r0, #0x16]       @ PC = -0xB5
    ldr r1, =0x00B5
    strh r1, [r0, #0x1E]       @ PD
    @ WINOUT: outside=0(backdrop), objwin(high byte)=BG0(bit8)=0x01
    ldr r1, =0x0100
    strh r1, [r12, #0x4A]
    @ DISPCNT mode0|BG0|OBJ|OBJwin|1D
    ldr r1, =0x9140
    strh r1, [r12]
forever:
    b forever
