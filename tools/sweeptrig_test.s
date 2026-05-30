.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r2, =0x04000000
    mov r1, #0
    strh r1, [r2]
    ldr r2, =0x04000084
    mov r1, #0x80
    strh r1, [r2]            @ master sound on
    ldr r2, =0x04000080
    ldr r1, =0x1177
    strh r1, [r2]
    ldr r2, =0x04000060
    mov r1, #0x01            @ NR10: shift=1, increase, period=0
    strh r1, [r2]
    ldr r1, =0xF080
    strh r1, [r2, #2]        @ NR11/NR12
    ldr r1, =0x85DC          @ NR13/NR14: freq=1500 + trigger
    strh r1, [r2, #4]
    ldr r2, =0x04000084
    ldrh r1, [r2]
    and r1, r1, #1           @ ch1 status flag
    ldr r2, =0x05000000
    cmp r1, #0
    bne on
    ldr r3, =0x001F          @ red = disabled on trigger (overflow check ran)
    strh r3, [r2]
    b done
on:
    ldr r3, =0x03E0          @ green = still on (no immediate check)
    strh r3, [r2]
done:
forever:
    b forever
    .ltorg
