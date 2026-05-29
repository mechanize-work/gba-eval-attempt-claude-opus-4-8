.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000000
    ldr r1, =0x4210          @ backdrop = gray
    strh r1, [r0]
    ldr r1, =0x00A0
    strh r1, [r12, #0x44]    @ WIN0V Y=0..160
    ldr r1, =0x50A0
    strh r1, [r12, #0x40]    @ WIN0H X=80..160
    ldr r1, =0x0020
    strh r1, [r12, #0x48]    @ WININ: WIN0 effects-enable only
    mov r1, #0
    strh r1, [r12, #0x4A]    @ WINOUT: no effects
    ldr r1, =0x00A0
    strh r1, [r12, #0x50]    @ BLDCNT: brighten(mode2,0x80) + backdrop target1(0x20)
    ldr r1, =0x0010
    strh r1, [r12, #0x54]    @ BLDY EVY=16 (full white)
    ldr r1, =0x2000
    strh r1, [r12]           @ DISPCNT: WIN0 enable
forever:
    b forever
