.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r0, =0x05000002
    ldr r1, =0x001F
    strh r1, [r0]              @ pal[1]=red
    ldr r0, =0x06000020        @ 4bpp tile 1
    mov r1, #1
    str r1, [r0]               @ byte0=0x01 (pixel(0,0)=idx1), rest 0
    mov r1, #0
    mov r2, #7
1:  str r1, [r0, #4]
    add r0, r0, #4
    subs r2, r2, #1
    bne 1b
    @ map at 0x06004000: tile1 normal, Hflip, Vflip, HVflip
    ldr r0, =0x06004000
    ldr r1, =0x04010001        @ map[0]=0x0001(normal), map[1]=0x0401(Hflip)
    str r1, [r0]
    ldr r1, =0x0C010801        @ map[2]=0x0801(Vflip), map[3]=0x0C01(HVflip)
    str r1, [r0, #4]
    ldr r1, =0x0800            @ BG0CNT screen base 8, 4bpp
    strh r1, [r12, #0x08]
    ldr r1, =0x0100
    strh r1, [r12]
forever:
    b forever
