.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ store known word to EWRAM[0]
    ldr r0, =0x02000000
    ldr r1, =0x12345678
    str r1, [r0]
    @ misaligned LDR: addr+1 -> read[0] ROR 8, addr+2 -> ROR 16, addr+3 -> ROR 24
    ldr r2, [r0, #1]         @ expect 0x78123456
    ldr r3, [r0, #2]         @ expect 0x56781234
    ldr r4, [r0, #3]         @ expect 0x34567812
    @ misaligned LDRH: addr+1 -> read[0] halfword ROR 8 (within the 16-bit)
    ldrh r5, [r0, #1]        @ LDRH from odd addr: read16[0] ror 8 = 0x5678 ror8 = 0x7856
    @ combine all into one value (xor), write to palette[0] backdrop (15 bits)
    eor r2, r2, r3
    eor r2, r2, r4
    eor r2, r2, r5
    ldr r6, =0x7FFF
    and r2, r2, r6
    ldr r1, =0x05000000
    strh r2, [r1]            @ backdrop = combined result
    mov r1, #0
    strh r1, [r12]           @ DISPCNT mode0 (backdrop shows)
forever:
    b forever
