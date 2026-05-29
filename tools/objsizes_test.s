@ All 12 OBJ sizes (shape 0/1/2 x size 0-3). Each sprite a solid red box of
@ its dimensions; verifies mine's sprite size table matches oracle.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ OBJ palette[1] = red
    ldr r1, =0x05000202
    ldr r2, =0x001F
    strh r2, [r1]
    @ fill OBJ tiles 0-63 with index 1 (2048 bytes @ 0x06010000)
    ldr r1, =0x06010000
    ldr r2, =0x11111111
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #2048
    blt 1b
    @ write 12 OAM entries from the table
    ldr r4, =oamtab
    ldr r5, =0x07000000
    mov r3, #0
2:  add r6, r4, r3, lsl #2     @ table entry = 2 halfwords (attr0,attr1) = 4 bytes
    ldrh r1, [r6]              @ attr0
    add r7, r5, r3, lsl #3     @ OAM entry = 8 bytes
    strh r1, [r7]
    ldrh r1, [r6, #2]          @ attr1
    strh r1, [r7, #2]
    mov r1, #0
    strh r1, [r7, #4]          @ attr2 = tile 0
    add r3, r3, #1
    cmp r3, #12
    blt 2b
    @ DISPCNT mode0 | OBJ(0x1000) | 1D(0x40)
    ldr r1, =0x1040
    strh r1, [r0]
forever:
    b forever
    .align 2
oamtab:
    @ attr0 = Y | shape<<14 ; attr1 = X | size<<14
    .hword 8,        8          @ 8x8   sh0 sz0
    .hword 8,        (24|0x4000)  @ 16x16 sh0 sz1
    .hword 8,        (60|0x8000)  @ 32x32 sh0 sz2
    .hword 8,        (100|0xC000) @ 64x64 sh0 sz3
    .hword (100|0x4000), 8         @ 16x8  sh1 sz0
    .hword (100|0x4000), (32|0x4000) @ 32x8 sh1 sz1
    .hword (112|0x4000), (72|0x8000) @ 32x16 sh1 sz2
    .hword (128|0x4000), (120|0xC000) @ 64x32 sh1 sz3
    .hword (80|0x8000), 8          @ 8x16  sh2 sz0
    .hword (80|0x8000), (24|0x4000)  @ 8x32  sh2 sz1
    .hword (80|0x8000), (40|0x8000)  @ 16x32 sh2 sz2
    .hword (60|0x8000), (200|0xC000) @ 32x64 sh2 sz3
