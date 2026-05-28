.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r6, =0x04000000
    @ SWI 0x06 Div: r0=numerator, r1=denominator -> r0=quotient
    mov r0, #1000
    mov r1, #7
    swi #0x060000
    @ r0 should be 142 (1000/7). Write quotient to palette[0] as a color.
    ldr r2, =0x05000000
    strh r0, [r2]
    @ Also test SWI 0x09 Sqrt: r0=input -> r0=sqrt
    mov r0, #144
    swi #0x090000
    @ r0 = 12. write to palette[1]
    strh r0, [r2, #2]
    mov r1, #0
    strh r1, [r6]        @ DISPCNT=0, show backdrop (palette0)
forever:
    b forever
