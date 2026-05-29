.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r0, #0
    strh r0, [r12]
    @ src: Diff8 header 0x81, size 4 -> deltas [10,5,3,250] -> [10,15,18,12]
    ldr r1, =0x02000000
    ldr r2, =0x00000481        @ byte0=0x81, size=4
    str r2, [r1]
    mov r2, #10
    strb r2, [r1, #4]
    mov r2, #5
    strb r2, [r1, #5]
    mov r2, #3
    strb r2, [r1, #6]
    mov r2, #250
    strb r2, [r1, #7]
    @ Diff8bitUnFilterVram: r0=src, r1=dest(VRAM)
    ldr r0, =0x02000000
    ldr r1, =0x06000000
    swi 0x170000
    ldr r1, =0x06000000
    ldrh r3, [r1, #0]         @ 0x0F0A (15<<8|10)
    ldrh r4, [r1, #2]         @ 0x0C12 (12<<8|18)
    eor r3, r3, r4
    ldr r1, =0x7FFF
    and r3, r3, r1
    ldr r1, =0x05000000
    strh r3, [r1]
forever:
    b forever
