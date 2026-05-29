@ Mode-dependent VRAM byte-write boundary: 0x06010000 is BG(bitmap) in mode3
@ (byte write duplicates) but OBJ in mode0 (byte write ignored).
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4

main:
    ldr r0, =0x04000000
    ldr r6, =0x06010000
    ldr r7, =0x06010002

    @ mode 3: byte write to 0x10000 should DUPLICATE
    mov r1, #3
    strh r1, [r0]
    ldr r1, =0x5678
    strh r1, [r6]
    mov r1, #0xAB
    strb r1, [r6]
    ldrh r3, [r6]             @ expect 0xABAB

    @ mode 0: byte write to 0x10002 should be IGNORED (OBJ region)
    mov r1, #0
    strh r1, [r0]
    ldr r1, =0x1234
    strh r1, [r7]
    mov r1, #0xCD
    strb r1, [r7]
    ldrh r4, [r7]            @ expect 0x1234 (unchanged)

    eor r3, r3, r4
    ldr r1, =0x7FFF
    and r3, r3, r1
    ldr r1, =0x05000000
    strh r3, [r1]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
