.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ write 0x1234 to OBJ VRAM 0x06010000, read via 0x06018000 (32KB OBJ mirror)
    ldr r1, =0x06010000
    ldr r2, =0x1234
    strh r2, [r1]
    ldr r1, =0x06018000
    ldrh r6, [r1]             @ expect 0x1234
    @ write 0x5678 to 0x06000000, read via 0x06020000 (128KB repeat)
    ldr r1, =0x06000000
    ldr r2, =0x5678
    strh r2, [r1]
    ldr r1, =0x06020000
    ldrh r7, [r1]             @ expect 0x5678
    eor r6, r6, r7
    ldr r1, =0x7FFF
    and r6, r6, r1
    ldr r1, =0x05000000
    strh r6, [r1]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
