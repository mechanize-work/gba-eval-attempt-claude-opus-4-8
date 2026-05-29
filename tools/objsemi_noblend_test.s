.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x7C00          @ backdrop blue
    strh r1, [r0]
    ldr r0, =0x05000200
    ldr r1, =0x001F          @ OBJ pal[1] red
    strh r1, [r0, #2]
    ldr r0, =0x06010000
    ldr r1, =0x11111111
    mov r3, #8
1:  str r1, [r0], #4
    subs r3, r3, #1
    bne 1b
    @ semi-transparent sprite (mode1 = attr0 0x0400) at (100,76) 16x16
    ldr r0, =0x07000000
    ldr r1, =0x044C          @ y=76 + mode1(0x400)
    strh r1, [r0]
    ldr r1, =0x4064          @ x=100 size1
    strh r1, [r0, #2]
    ldr r1, =0x0000
    strh r1, [r0, #4]
    @ BLDCNT: alpha mode (0x40) but NO 2nd target -> semi-trans OBJ shows opaque
    ldr r1, =0x0040
    strh r1, [r12, #0x50]
    ldr r1, =0x0808
    strh r1, [r12, #0x52]
    @ DISPCNT OBJ + 1D
    ldr r1, =0x1040
    strh r1, [r12]
forever:
    b forever
