.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x7C00           @ BG palette[1] = blue
    strh r1, [r0, #2]
    ldr r1, =0x001F           @ OBJ palette[1] = red
    ldr r2, =0x05000202
    strh r1, [r2]
    @ BG tile0 + OBJ tile0 = index1
    ldr r0, =0x06000000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    ldr r0, =0x06010000
    mov r3, #8
2:  str r1, [r0], #4
    subs r3, r3, #1
    bne 2b
    ldr r1, =0x0800
    strh r1, [r12, #8]        @ BG0CNT prio 0
    @ OAM: 8x8 sprite at (40,40), priority 1 (below BG0)
    ldr r0, =0x07000000
    mov r1, #40
    strh r1, [r0]
    ldr r1, =0x0028
    strh r1, [r0, #2]
    ldr r1, =0x0400           @ tile0, priority 1
    strh r1, [r0, #4]
    @ BLDCNT: alpha(0x40) | BG0 t1(0x01) | OBJ t2(0x1000)
    ldr r1, =0x1041
    strh r1, [r12, #0x50]
    ldr r1, =0x0808
    strh r1, [r12, #0x52]
    ldr r1, =0x1140           @ DISPCNT mode0|BG0|OBJ|1D
    strh r1, [r12]
forever:
    b forever
