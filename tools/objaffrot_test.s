.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r0, #0
    strh r0, [r12]            @ DISPCNT=0 FIRST
    ldr r1, =0x05000000
    ldr r2, =0x001F           @ palette[0]=red MARKER (stays red if SWI hangs)
    strh r2, [r1]
    @ src struct @ 0x02000000: ScaleX=0x100, ScaleY=0x100, Angle=0
    ldr r1, =0x02000000
    ldr r2, =0x100
    strh r2, [r1, #0]         @ ScaleX
    strh r2, [r1, #2]         @ ScaleY
    mov r2, #0
    ldr r2, =0x2000
    strh r2, [r1, #4]         @ Angle=45deg
    @ ObjAffineSet: r0=src, r1=dest, r2=count, r3=stride(2=continuous)
    ldr r0, =0x02000000
    ldr r1, =0x02000010
    mov r2, #1
    mov r3, #2
    swi 0x0F0000
    @ read PA (dest[0])
    ldr r1, =0x02000010
    ldrh r3, [r1]             @ PA
    ldrh r4, [r1, #2]         @ PB
    eor r3, r3, r4
    ldr r1, =0x7FFF
    and r3, r3, r1
    ldr r1, =0x05000000
    strh r3, [r1]             @ overwrite marker with PA
forever:
    b forever
