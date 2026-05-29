.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x001F
    strh r1, [r0]              @ palette[0]=red
    ldr r1, =0x7FFF
    strh r1, [r0, #4]          @ palette[2]=white
    mov r0, #0x04
    swi 0x010000               @ RegisterRamReset: clear palette
    mov r1, #0
    strh r1, [r12]             @ DISPCNT=0 (clear any forced-blank)
    @ read palette[0] and [2] back to VRAM via a copy, show as backdrop
    ldr r0, =0x05000000
    ldrh r2, [r0]
    ldr r3, =0x06000000
    strh r2, [r3]              @ pixel0 = palette[0] after reset
    ldrh r2, [r0, #4]
    strh r2, [r3, #2]          @ pixel1 = palette[2] after reset
    ldr r1, =0x0403
    strh r1, [r12]             @ mode 3 to show pixels
forever:
    b forever
