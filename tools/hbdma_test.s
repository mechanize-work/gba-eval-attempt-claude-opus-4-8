.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    @ build 160-entry color table in EWRAM (color[i] = i<<5 | i)
    ldr r0, =0x02000000
    mov r2, #0
tbl:
    lsl r1, r2, #5
    orr r1, r1, r2
    strh r1, [r0], #2
    add r2, r2, #1
    cmp r2, #160
    blt tbl
    @ DMA0: src=table(inc), dst=palette0(fixed), count=1, hblank, repeat, 16-bit
    ldr r1, =0x02000000
    str r1, [r12, #0xB0]
    ldr r1, =0x05000000
    str r1, [r12, #0xB4]
    ldr r1, =0xA2400001        @ enable|hblank|repeat|dstfixed, count=1
    str r1, [r12, #0xB8]
    @ DISPCNT: backdrop only (no BG)
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
