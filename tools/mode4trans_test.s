@ Mode 4 index-0 transparency: BG2 (prio0) all index0, OBJ (red, prio1, BELOW BG2).
@ If mode-4 idx0 is transparent, the OBJ shows through; if opaque, it's hidden.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r1, =0x05000000
    ldr r2, =0x7C00           @ palette[0] = blue (backdrop + BG2 idx0)
    strh r2, [r1]
    ldr r1, =0x05000202
    ldr r2, =0x001F           @ OBJ palette[1] = red
    strh r2, [r1]
    @ bitmap stays all 0 (index 0). OBJ tile 512 @ 0x06014000 = index1
    ldr r1, =0x06014000
    ldr r2, =0x11111111
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 1b
    @ BG2 identity affine, priority 0
    mov r1, #0x100
    strh r1, [r0, #0x20]
    mov r1, #0
    strh r1, [r0, #0x22]
    strh r1, [r0, #0x24]
    mov r1, #0x100
    strh r1, [r0, #0x26]
    mov r1, #0
    str r1, [r0, #0x28]
    str r1, [r0, #0x2C]
    strh r1, [r0, #0xC]       @ BG2CNT priority 0
    @ OAM: 8x8 sprite at (40,40), tile 512, priority 1 (below BG2)
    ldr r1, =0x07000000
    mov r2, #40
    strh r2, [r1]
    ldr r2, =0x0028           @ x=40, 8x8
    strh r2, [r1, #2]
    ldr r2, =0x0600           @ tile512(0x200) | prio1(0x400)
    strh r2, [r1, #4]
    ldr r1, =0x1444           @ DISPCNT mode4 | BG2 | OBJ | 1D
    strh r1, [r0]
forever:
    b forever
