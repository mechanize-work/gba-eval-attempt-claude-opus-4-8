.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4
main:
    ldr r0, =0x04000000
    @ palette: index 1 = mid-gray, 2 = red
    ldr r1, =0x05000000
    ldr r2, =0x4210            @ gray-ish (16,16,16)
    strh r2, [r1, #2]
    ldr r2, =0x001F            @ red
    strh r2, [r1, #4]
    @ mode 4: fill VRAM with index 1 (left half) and 2 (right half)
    ldr r1, =0x06000000
    mov r3, #0
    ldr r5, =0x9600           @ 240*160 = 38400 bytes
fillv:
    @ left 120 -> 1, right -> 2 ; simple: alternate by bit
    ldr r2, =0x0101           @ two pixels index 1
    strh r2, [r1, r3]
    add r3, r3, #2
    cmp r3, r5
    blt fillv
    @ BLDCNT (0x50): target1 = BG2 (bit2), mode 2 (brighten) bits6-7=10
    ldr r1, =0x0084           @ bit2 (BG2 t1) | (2<<6)
    strh r1, [r0, #0x50]
    @ BLDY (0x54) = 8 (half brighten)
    mov r1, #8
    strh r1, [r0, #0x54]
    @ DISPCNT: mode 4, BG2 on
    ldr r1, =0x0404
    strh r1, [r0]
forever:
    b forever
