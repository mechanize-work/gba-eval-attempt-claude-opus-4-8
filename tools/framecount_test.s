.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0
    strh r1, [r12]          @ DISPCNT=0, backdrop shows
    ldr r5, =0x05000000     @ palette[0]
    mov r4, #1              @ counter (start at 1 so frame0 differs from black)
loop:
1:  ldrh r1, [r12, #6]
    cmp r1, #160
    blt 1b
    strh r4, [r5]           @ backdrop = counter
    add r4, r4, #1
2:  ldrh r1, [r12, #6]
    cmp r1, #160
    bge 2b
    b loop
