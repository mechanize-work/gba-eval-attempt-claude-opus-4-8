.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x02000000
    ldr r1, =target
    str r1, [r0]              @ [buffer] = target address
    ldr r2, =0x05000000
    ldr r1, =0x001F
    strh r1, [r2]             @ backdrop red (if LDM doesn't branch)
    ldr r2, =0x04000000
    mov r1, #0
    strh r1, [r2]             @ DISPCNT=0
    .word 0xE8B00000          @ ldmia r0!, {} (empty rlist) -> PC = [r0] = target
fall:
    b fall
    .ltorg
target:
    ldr r2, =0x05000000
    ldr r1, =0x03E0           @ green
    strh r1, [r2]
loop:
    b loop
    .ltorg
