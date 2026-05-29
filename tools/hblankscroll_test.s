@ Per-line scroll via HBlank IRQ: BG0HOFS = VCOUNT each line -> diagonal shear.
@ Tests the common parallax/ripple technique (register change affects NEXT line).
.arm
.section .text
.global _start
_start:
    b main
    .space 0xC0 - 4

main:
    ldr r0, =0x04000000

    @ palette 1..8 distinct
    ldr r1, =0x05000000
    add r5, r1, #2
    ldr r2, =0x001F          @1 red
    strh r2, [r5], #2
    ldr r2, =0x03E0          @2 green
    strh r2, [r5], #2
    ldr r2, =0x7C00          @3 blue
    strh r2, [r5], #2
    ldr r2, =0x7FFF          @4 white
    strh r2, [r5], #2
    ldr r2, =0x03FF          @5 cyan
    strh r2, [r5], #2
    ldr r2, =0x7FE0          @6 yellow
    strh r2, [r5], #2
    ldr r2, =0x7C1F          @7 magenta
    strh r2, [r5], #2
    ldr r2, =0x4210          @8 grey
    strh r2, [r5], #2

    @ BG0 tile1 @ 0x06000020: 8 columns = indices 1..8, all rows
    ldr r1, =0x06000020
    ldr r2, =0x43212143       @ wrong order placeholder, fix below
    @ row bytes: b0=0x21 b1=0x43 b2=0x65 b3=0x87
    ldr r2, =0x87654321
    mov r3, #0
trow:
    str r2, [r1, r3]
    add r3, r3, #4
    cmp r3, #32
    blt trow

    @ map @ 0x06004000 (block8): all tile 1
    ldr r1, =0x06004000
    mov r4, #1
    mov r3, #0
tmap:
    strh r4, [r1, r3]
    add r3, r3, #2
    cmp r3, #2048
    blt tmap

    @ BG0CNT: charbase0, screenbase block8 (0x0800)
    ldr r1, =0x0800
    strh r1, [r0, #8]

    @ user IRQ handler
    ldr r1, =0x03007FFC
    ldr r2, =irq_handler
    str r2, [r1]
    @ DISPSTAT: HBlank IRQ enable (bit4)
    mov r1, #0x10
    strh r1, [r0, #4]
    @ IE = HBlank(bit1), IME=1
    ldr r3, =0x04000200
    mov r1, #2
    strh r1, [r3]
    mov r1, #1
    strh r1, [r3, #8]

    @ DISPCNT = mode0 | BG0
    ldr r1, =0x0100
    strh r1, [r0]
forever:
    b forever
    .ltorg

irq_handler:
    ldr r0, =0x04000202
    mov r1, #2
    strh r1, [r0]              @ ack HBlank
    ldr r2, =0x03007FF8
    ldrh r3, [r2]
    orr r3, r3, #2
    strh r3, [r2]
    ldr r0, =0x04000000
    ldrh r1, [r0, #6]          @ VCOUNT
    strh r1, [r0, #0x10]       @ BG0HOFS = vcount
    bx lr
    .ltorg
