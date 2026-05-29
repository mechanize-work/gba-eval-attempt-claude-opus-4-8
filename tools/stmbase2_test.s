.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x02000040      @ base, lowest in list -> stores ORIGINAL
    ldr r1, =0x1111
    stmia r0!, {r0, r1}
    ldr r1, =0x02000040
    ldr r0, [r1]             @ [buffer] = stored base
    ldr r1, =0x7FFF
    and r3, r0, r1           @ 0x40 = original, 0x48 = new
    ldr r1, =0x05000000
    strh r3, [r1]
    ldr r2, =0x04000000
    mov r1, #0
    strh r1, [r2]
forever:
    b forever
    .ltorg
