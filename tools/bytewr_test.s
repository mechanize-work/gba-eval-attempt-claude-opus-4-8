.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0
    strh r1, [r12]             @ mode 0
    ldr r0, =0x05000200
    mov r1, #0xAB
    strb r1, [r0]
    ldrh r3, [r0]              @ palette dup -> 0xABAB
    ldr r0, =0x06010000
    ldr r1, =0x1234
    strh r1, [r0]
    mov r1, #0xFF
    strb r1, [r0]              @ OBJ-VRAM byte write (mode0) -> ignored
    ldrh r4, [r0]              @ expect 0x1234
    ldr r0, =0x07000000
    ldr r1, =0x5678
    strh r1, [r0]
    mov r1, #0xFF
    strb r1, [r0]              @ OAM byte write -> ignored
    ldrh r5, [r0]              @ expect 0x5678
    ldr r6, =0x06000000
    strh r3, [r6]
    strh r4, [r6, #2]
    strh r5, [r6, #4]
    ldr r1, =0x0403
    strh r1, [r12]
forever:
    b forever
