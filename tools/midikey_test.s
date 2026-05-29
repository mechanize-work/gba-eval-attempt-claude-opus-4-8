.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r0, #0
    strh r0, [r12]            @ DISPCNT=0 FIRST
    ldr r1, =0x05000000
    ldr r2, =0x001F           @ palette[0]=red MARKER
    strh r2, [r1]
    @ WaveData struct @ 0x02000000: freq (u32) at offset 4
    ldr r1, =0x02000000
    mov r2, #0
    str r2, [r1, #0]
    ldr r2, =0x00040000       @ freq at offset 4
    str r2, [r1, #4]
    str r2, [r1, #8]
    @ MidiKey2Freq: r0=WaveData, r1=key(60), r2=fine(0)
    ldr r0, =0x02000000
    mov r1, #60
    mov r2, #0
    swi 0x1F0000
    @ fold r0 (result freq) to 15 bits
    mov r4, r0, lsr #16
    eor r0, r0, r4
    ldr r1, =0x7FFF
    and r0, r0, r1
    ldr r1, =0x05000000
    strh r0, [r1]
forever:
    b forever
