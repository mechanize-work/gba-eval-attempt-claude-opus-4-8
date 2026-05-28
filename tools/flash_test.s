.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
flashid:
    .ascii "FLASH_V123\0"
    .align 2
main:
    ldr r0, =0x04000000
    ldr r6, =0x0E000000        @ Flash base
    @ Write byte 0x42 to Flash addr 0 via command sequence
    ldr r1, =0x0E005555
    mov r2, #0xAA
    strb r2, [r1]
    ldr r1, =0x0E002AAA
    mov r2, #0x55
    strb r2, [r1]
    ldr r1, =0x0E005555
    mov r2, #0xA0              @ write byte command
    strb r2, [r1]
    mov r2, #0x42
    strb r2, [r6]             @ write 0x42 to addr 0
    @ small delay
    mov r5, #0x100
fw: subs r5,r5,#1
    bne fw
    @ read back addr 0
    ldrb r3, [r6]
    @ set palette[0] = read value as color
    ldr r2, =0x05000000
    strh r3, [r2]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
