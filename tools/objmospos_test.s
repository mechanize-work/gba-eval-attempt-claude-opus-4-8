@ OBJ mosaic alignment: 8x8 sprite with per-column gradient, mosaic mos_h=4,
@ placed at X=42 (not a multiple of 4). Screen-relative vs sprite-relative
@ mosaic quantize the columns differently. Compare to oracle.
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ OBJ palette[1..8] distinct
    ldr r1, =0x05000200
    ldr r2, =0x001F
    strh r2, [r1, #2]          @1 red
    ldr r2, =0x03E0
    strh r2, [r1, #4]          @2 green
    ldr r2, =0x7C00
    strh r2, [r1, #6]          @3 blue
    ldr r2, =0x7FFF
    strh r2, [r1, #8]          @4 white
    ldr r2, =0x03FF
    strh r2, [r1, #10]         @5 cyan
    ldr r2, =0x7FE0
    strh r2, [r1, #12]         @6 yellow
    ldr r2, =0x7C1F
    strh r2, [r1, #14]         @7 magenta
    ldr r2, =0x4210
    strh r2, [r1, #16]         @8 grey
    @ OBJ tile0: each column index 1..8
    ldr r1, =0x06010000
    ldr r2, =0x87654321
    mov r3, #0
1:  str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt 1b
    @ MOSAIC (0x4C): OBJ H mosaic = 4 (bits8-11 = 3)
    ldr r1, =0x0300
    strh r1, [r0, #0x4C]
    @ OAM: 8x8 sprite at (42,40), mosaic enabled (attr0 bit12)
    ldr r1, =0x07000000
    ldr r2, =0x1028           @ y=40, mosaic(0x1000), 8x8
    strh r2, [r1]
    mov r2, #42               @ x=42
    strh r2, [r1, #2]
    mov r2, #0
    strh r2, [r1, #4]
    ldr r1, =0x1040           @ DISPCNT mode0|OBJ|1D
    strh r1, [r0]
forever:
    b forever
