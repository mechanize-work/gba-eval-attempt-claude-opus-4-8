.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    ldr r7, =0x02000000        @ buffer base in EWRAM

    @ Build WRITE stream (81 halfwords): "10" + 6 addr(0) + 64 data(1) + stop(0) [6-bit/512B]
    mov r2, #0                 @ idx
    mov r1, #1
    strh r1, [r7]              @ bit0 = 1
    mov r1, #0
    strh r1, [r7, #2]          @ bit1 = 0
    @ addr bits [2..16) = 0
    mov r2, #2
zaddr:
    add r3, r7, r2, lsl #1
    strh r1, [r3]
    add r2, r2, #1
    cmp r2, #8
    blt zaddr
    @ data bits [16..80) = 1
    mov r1, #1
dat:
    add r3, r7, r2, lsl #1
    strh r1, [r3]
    add r2, r2, #1
    cmp r2, #72
    blt dat
    @ stop bit [80] = 0
    mov r1, #0
    add r3, r7, r2, lsl #1
    strh r1, [r3]

    @ DMA3 write stream -> EEPROM 0x0D000000, 81 units, 16-bit
    ldr r1, =0x0D000000
    str r7, [r0, #0xD4]        @ DMA3 src
    str r1, [r0, #0xD8]        @ DMA3 dst
    mov r1, #73
    strh r1, [r0, #0xDC]       @ count
    ldr r1, =0x8000            @ enable, 16-bit, immediate
    strh r1, [r0, #0xDE]
    @ wait a bit
    mov r5, #0x1000
wd: subs r5, r5, #1
    bne wd

    @ Build READ request (17 hw): "11" + 6 addr(0) + stop(0)
    ldr r8, =0x02000400
    mov r1, #1
    strh r1, [r8]
    strh r1, [r8, #2]
    mov r1, #0
    mov r2, #2
zr:
    add r3, r8, r2, lsl #1
    strh r1, [r3]
    add r2, r2, #1
    cmp r2, #9
    blt zr
    @ DMA3 read request -> EEPROM, 17 units
    ldr r1, =0x0D000000
    str r8, [r0, #0xD4]
    str r1, [r0, #0xD8]
    mov r1, #9
    strh r1, [r0, #0xDC]
    ldr r1, =0x8000
    strh r1, [r0, #0xDE]

    @ DMA3 read 68 bits FROM EEPROM -> 0x02000800
    ldr r9, =0x02000800
    ldr r1, =0x0D000000
    str r1, [r0, #0xD4]        @ src = EEPROM
    str r9, [r0, #0xD8]        @ dst = buffer
    mov r1, #68
    strh r1, [r0, #0xDC]
    ldr r1, =0x8000
    strh r1, [r0, #0xDE]

    @ Check data bit 4 (first real data bit). If 1 -> palette0 = green, else red
    ldrh r2, [r9, #8]          @ readbuf[4] (offset 4*2=8)
    ldr r1, =0x05000000
    tst r2, #1
    ldrne r3, =0x03E0          @ green if bit set
    ldreq r3, =0x001F          @ red if not
    strh r3, [r1]
    mov r1, #0
    strh r1, [r0]              @ mode 0, show backdrop
forever:
    b forever
