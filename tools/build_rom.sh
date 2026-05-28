#!/bin/bash
# build_rom.sh <name.s> <out.gba>
set -e
SRC=$1; OUT=$2
arm-none-eabi-as -mcpu=arm7tdmi "$SRC" -o /tmp/rom.o
ld.lld -Ttext=0x08000000 --oformat=elf /tmp/rom.o -o /tmp/rom.elf 2>/dev/null || arm-none-eabi-ld -Ttext=0x08000000 /tmp/rom.o -o /tmp/rom.elf
arm-none-eabi-objcopy -O binary /tmp/rom.elf "$OUT"
# Splice in a valid header (logo + fixups) from anguna, preserving our entry branch.
python3 -c "
import sys
rom=bytearray(open('$OUT','rb').read())
hdr=open('dev-roms/anguna.gba','rb').read()[:0xC0]
# keep our entry branch at 0..3, use anguna's logo+header for 4..0xBF
for i in range(4,0xC0):
    rom[i]=hdr[i]
open('$OUT','wb').write(rom)
print('rom size', len(rom))
"
