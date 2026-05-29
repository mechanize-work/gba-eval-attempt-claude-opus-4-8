.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    mov r1, #0x80
    strh r1, [r0, #0x84]
    mov r1, #2
    strh r1, [r0, #0x82]
    ldr r1, =0x4477
    strh r1, [r0, #0x80]
    mov r1, #0x80
    strh r1, [r0, #0x70]
    @ write square: 8 bytes 0xFF (16 samples=15), 8 bytes 0x00 (16 samples=0)
    ldr r2, =0x04000090
    ldr r3, =0xFFFFFFFF
    str r3, [r2]
    str r3, [r2, #4]
    mov r3, #0
    str r3, [r2, #8]
    str r3, [r2, #12]
    mov r1, #0xC0
    strh r1, [r0, #0x70]
    ldr r1, =0x2000          @ volume 100%
    strh r1, [r0, #0x72]
    ldr r1, =0x8400          @ freq + trigger
    strh r1, [r0, #0x74]
    mov r1, #0
    strh r1, [r0]
forever:
    b forever
