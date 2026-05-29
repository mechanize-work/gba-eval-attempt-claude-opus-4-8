.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000202
    ldr r1, =0x03E0          @ OBJ pal[1]=green
    strh r1, [r0]
    @ OBJ tiles 0-15 (32x32) = index 1
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r3, #128
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ matrix 0 = identity: PA@0x07000006=0x100, PB@0E=0, PC@16=0, PD@1E=0x100
    ldr r0, =0x07000000
    ldr r1, =0x0100
    strh r1, [r0, #6]        @ PA
    mov r1, #0
    strh r1, [r0, #0xE]      @ PB
    strh r1, [r0, #0x16]     @ PC
    ldr r1, =0x0100
    strh r1, [r0, #0x1E]     @ PD
    @ OAM[0]: attr0 = affine(0x100)+double(0x200)+y=40 = 0x0328
    ldr r1, =0x0328
    strh r1, [r0]
    @ attr1 = x=80(0x50) + size2(0x8000) + matrix0 = 0x8050
    ldr r1, =0x8050
    strh r1, [r0, #2]
    mov r1, #0
    strh r1, [r0, #4]        @ attr2 tile 0
    ldr r1, =0x1040          @ DISPCNT OBJ + 1D
    strh r1, [r12]
forever:
    b forever
