.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r12, =0x04000000
    mov r1, #0x80
    strh r1, [r12, #0x84]     @ master enable
    ldr r1, =0xF03F           @ ch1 env vol15 + length=0x3F (very short)
    strh r1, [r12, #0x62]
    ldr r1, =0x1177           @ SOUNDCNT_L ch1 L/R
    strh r1, [r12, #0x80]
    ldr r1, =0xC400           @ ch1 freq + length-enable(0x4000) + trigger(0x8000)
    strh r1, [r12, #0x64]
    @ delay ~5 frames (length expires after ~0.23 frame)
    ldr r3, =70000
1:  subs r3, r3, #1
    bne 1b
    ldrh r2, [r12, #0x84]     @ SOUNDCNT_X: bit0 = ch1 status (should be 0 after expiry)
    ldr r3, =0x05000000
    strh r2, [r3]
    mov r1, #0
    strh r1, [r12]
forever:
    b forever
