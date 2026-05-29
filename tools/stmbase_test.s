.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    ldr r10, =0x05000000   @ palette
    @ Case 2: base NOT lowest in rlist -> should store WRITEBACK value
    ldr r4, =0x02000010
    mov r5, r4             @ save original base
    ldr r0, =0x1111
    stmia r4!, {r0, r4}    @ r0<r4, so r4 stored 2nd; ARM7TDMI stores writeback (orig+8)
    ldr r3, [r5, #4]       @ read stored r4
    strh r3, [r10]         @ palette[0] = low16 (writeback=0x0018, orig=0x0010)
    @ Case 1: base IS lowest -> should store ORIGINAL value
    ldr r6, =0x02000020
    mov r7, r6
    ldr r1, =0x2222
    stmia r6!, {r6, r1}    @ r6 lowest -> stores original r6 (0x0020)
    ldr r3, [r7]
    strh r3, [r10, #2]     @ palette[1] = low16 (orig=0x0020)
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
