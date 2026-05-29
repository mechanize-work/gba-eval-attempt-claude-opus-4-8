//! System bus: memory map, I/O registers, timing, and component stepping.

use crate::apu::Apu;
use crate::cpu::{Access, Bus};
use crate::dma::Dma;
use crate::ppu::{self, Ppu};
use crate::save::{Save, SaveType};
use crate::sched::Sched;
use crate::timer::Timers;

// Interrupt bit positions.
pub const IRQ_VBLANK: u16 = 1 << 0;
pub const IRQ_HBLANK: u16 = 1 << 1;
pub const IRQ_VCOUNT: u16 = 1 << 2;
pub const IRQ_TIMER0: u16 = 1 << 3;
pub const IRQ_DMA0: u16 = 1 << 8;
pub const IRQ_KEYPAD: u16 = 1 << 12;

pub struct SysBus {
    pub bios: Box<[u8]>,   // 16 KiB
    pub ewram: Box<[u8]>,  // 256 KiB
    pub iwram: Box<[u8]>,  // 32 KiB
    pub rom: Vec<u8>,
    pub save: Save,
    pub eeprom_addr_bits: u32,

    pub ppu: Ppu,
    pub apu: Apu,
    pub timers: Timers,
    pub dma: Dma,
    pub sched: Sched,

    // Interrupt control.
    pub ie: u16,
    pub if_: u16,
    pub ime: bool,

    pub keyinput: u16, // active-low (1 = released)
    pub keycnt: u16,

    pub waitcnt: u16,
    pub memctrl: u32,
    pub ewram_c16: u32,
    pub ewram_c32: u32,
    pub postflg: u8,
    pub haltcnt: u8,
    pub halted: bool,

    pub frame_complete: bool,

    // Open bus / last fetched value.
    pub open_bus: u32,
    pub last_bios: u32,

    // DMA scheduling: bitmask of channels that should run now.
    pub dma_pending: u8,

    // Pending sound FIFO refill requests (set on timer overflow).
    pub fifo_a_request: bool,
    pub fifo_b_request: bool,

    // Wait state tables (cycles for N and S access), recomputed on WAITCNT write.
    ws_n: [u32; 16], // by region nibble (0x8..0xE)
    ws_s: [u32; 16],
    ws_n32: [u32; 16],
    ws_s32: [u32; 16],
    sram_wait: u32,

    // IRQ line caching.
    pub irq_line: bool,
}

const REGION_TIMINGS_NSEQ: [u32; 4] = [4, 3, 2, 8];

impl SysBus {
    pub fn new() -> Self {
        let mut b = SysBus {
            bios: vec![0u8; 16 * 1024].into_boxed_slice(),
            ewram: vec![0u8; 256 * 1024].into_boxed_slice(),
            iwram: vec![0u8; 32 * 1024].into_boxed_slice(),
            rom: Vec::new(),
            save: Save::new(SaveType::Sram),
            eeprom_addr_bits: 14,
            ppu: Ppu::new(),
            apu: Apu::new(),
            timers: Timers::new(),
            dma: Dma::new(),
            sched: Sched::new(),
            ie: 0,
            if_: 0,
            ime: false,
            keyinput: 0x03FF,
            keycnt: 0,
            waitcnt: 0,
            memctrl: 0x0D00_0020,
            ewram_c16: 3,
            ewram_c32: 6,
            postflg: 0,
            haltcnt: 0,
            halted: false,
            frame_complete: false,
            open_bus: 0,
            last_bios: 0,
            dma_pending: 0,
            fifo_a_request: false,
            fifo_b_request: false,
            ws_n: [1; 16],
            ws_s: [1; 16],
            ws_n32: [1; 16],
            ws_s32: [1; 16],
            sram_wait: 5,
            irq_line: false,
        };
        b.update_waitstates();
        b
    }

    pub fn load_bios(&mut self, data: &[u8]) {
        let n = data.len().min(self.bios.len());
        self.bios[..n].copy_from_slice(&data[..n]);
    }

    pub fn load_rom(&mut self, data: &[u8]) {
        self.rom = data.to_vec();
        let ty = crate::save::detect(data);
        self.save = Save::new(ty);
        self.eeprom_addr_bits = match ty {
            SaveType::Eeprom512 => 6,
            _ => 14,
        };
    }

    pub fn reset(&mut self) {
        self.ppu.reset();
        self.apu.reset();
        self.timers = Timers::new();
        self.dma = Dma::new();
        self.sched = Sched::new();
        for b in self.ewram.iter_mut() { *b = 0; }
        for b in self.iwram.iter_mut() { *b = 0; }
        self.ie = 0;
        self.if_ = 0;
        self.ime = false;
        self.keyinput = 0x03FF;
        self.keycnt = 0;
        self.waitcnt = 0;
        self.memctrl = 0x0D00_0020;
        self.postflg = 0;
        self.haltcnt = 0;
        self.halted = false;
        self.frame_complete = false;
        self.open_bus = 0;
        self.dma_pending = 0;
        self.fifo_a_request = false;
        self.fifo_b_request = false;
        self.update_waitstates();
        self.update_ewram_wait();
    }

    pub(crate) fn update_ewram_wait(&mut self) {
        // Bits 24-27 of memctrl: WRAM 256K waitstate = 15 - value.
        let v = (self.memctrl >> 24) & 0xF;
        let waits = if v >= 15 { 15 } else { 15 - v };
        self.ewram_c16 = 1 + waits;
        // oracle charges EWRAM 32-bit at the single-access cost, not doubled
        // (confirmed by STM calib AND meteorain — doubling regresses it to 100%).
        self.ewram_c32 = 1 + waits;
        // If EWRAM disabled (bit0) we leave timings; edge case ignored.
    }

    pub(crate) fn update_waitstates(&mut self) {
        let w = self.waitcnt;
        // Access cycles = 1 + waitstate (hardware-accurate). When the game-pak
        // prefetch buffer is enabled (bit 14), sequential ROM fetches are served
        // from the buffer at 1 cycle.
        let prefetch = w & 0x4000 != 0;
        self.sram_wait = 1 + REGION_TIMINGS_NSEQ[(w & 0x3) as usize];
        // Non-sequential (branch target) access: full 1+waitstate when running
        // without prefetch; with the buffer enabled the target is often already
        // buffered, so we use the lower (GBATEK-literal) cost.
        let np1 = |raw: u32| if prefetch { raw } else { 1 + raw };
        let ws0_n = np1(REGION_TIMINGS_NSEQ[((w >> 2) & 0x3) as usize]);
        let ws0_s = if prefetch { 1 } else { 1 + if (w >> 4) & 1 == 1 { 1 } else { 2 } };
        let ws1_n = np1(REGION_TIMINGS_NSEQ[((w >> 5) & 0x3) as usize]);
        let ws1_s = if prefetch { 1 } else { 1 + if (w >> 7) & 1 == 1 { 1 } else { 4 } };
        let ws2_n = np1(REGION_TIMINGS_NSEQ[((w >> 8) & 0x3) as usize]);
        let ws2_s = if prefetch { 1 } else { 1 + if (w >> 10) & 1 == 1 { 1 } else { 8 } };

        for r in 0..16 {
            let (n, s) = match r {
                0x8 | 0x9 => (ws0_n, ws0_s),
                0xA | 0xB => (ws1_n, ws1_s),
                0xC | 0xD => (ws2_n, ws2_s),
                0xE | 0xF => (self.sram_wait, self.sram_wait),
                _ => (1, 1),
            };
            self.ws_n[r] = n;
            self.ws_s[r] = s;
            // 32-bit ROM access = two 16-bit accesses (N then S).
            self.ws_n32[r] = n + s;
            self.ws_s32[r] = s + s;
        }
    }

    /// Cycles for a memory access of the given width and access type at `addr`.
    #[inline]
    fn access_cycles(&self, addr: u32, width: u32, access: Access) -> u32 {
        let region = (addr >> 24) as usize & 0xF;
        match region {
            0x0 | 0x3 | 0x4 | 0x7 => 1, // BIOS, IWRAM, IO, OAM
            0x2 => {
                // EWRAM: the first access pays full cost; sequential accesses
                // within an LDM/STM burst are cheap (matches oracle block timing).
                let base = if width == 4 { self.ewram_c32 } else { self.ewram_c16 };
                match access {
                    Access::Seq => 1,
                    _ => base,
                }
            }
            0x5 | 0x6 => {
                // Palette / VRAM: 16-bit 1 cycle, 32-bit 2 cycles. During active
                // display the PPU contends for these memories, inserting +1 cycle.
                let base = if width == 4 { 2 } else { 1 };
                let active = self.ppu.vcount < 160
                    && self.ppu.dot < 960
                    && (self.ppu.dispcnt & 0x80) == 0;
                base + active as u32
            }
            0x8..=0xF => {
                if width == 4 {
                    match access {
                        Access::NonSeq => self.ws_n32[region],
                        Access::Seq => self.ws_s32[region],
                    }
                } else {
                    match access {
                        Access::NonSeq => self.ws_n[region],
                        Access::Seq => self.ws_s[region],
                    }
                }
            }
            _ => 1,
        }
    }

    #[inline]
    fn tick(&mut self, cycles: u32) {
        self.sched.add(cycles);
        self.step_ppu(cycles);
        if self.timers.any_enabled {
            self.step_timers(cycles);
        }
        self.apu.step(cycles);
    }

    // --- PPU stepping -----------------------------------------------------
    fn step_ppu(&mut self, cycles: u32) {
        let mut remaining = cycles;
        while remaining > 0 {
            let line_end = ppu::CYCLES_PER_LINE;
            let to_line_end = line_end - self.ppu.dot;
            let step = remaining.min(to_line_end);
            let prev_dot = self.ppu.dot;
            self.ppu.dot += step;
            remaining -= step;

            let line = self.ppu.vcount as u32;
            let hbl_cycle = 1006u32;
            if prev_dot < hbl_cycle && self.ppu.dot >= hbl_cycle {
                if line < ppu::VDRAW {
                    self.ppu.render_scanline(line);
                }
                self.ppu.dispstat |= 0x2;
                if self.ppu.dispstat & 0x10 != 0 {
                    self.if_ |= IRQ_HBLANK;
                }
                if line < ppu::VDRAW {
                    self.trigger_dma_hblank();
                }
            }

            if self.ppu.dot >= line_end {
                self.ppu.dot -= line_end;
                self.ppu.dispstat &= !0x2;
                let new_line = (self.ppu.vcount + 1) % ppu::TOTAL_LINES as u16;
                self.ppu.vcount = new_line;

                let vcount_setting = (self.ppu.dispstat >> 8) & 0xFF;
                if new_line == vcount_setting {
                    self.ppu.dispstat |= 0x4;
                    if self.ppu.dispstat & 0x20 != 0 {
                        self.if_ |= IRQ_VCOUNT;
                    }
                } else {
                    self.ppu.dispstat &= !0x4;
                }

                if new_line == ppu::VDRAW as u16 {
                    self.ppu.dispstat |= 0x1;
                    if self.ppu.dispstat & 0x8 != 0 {
                        self.if_ |= IRQ_VBLANK;
                    }
                    self.trigger_dma_vblank();
                } else if new_line == 0 {
                    self.ppu.dispstat &= !0x1;
                    self.frame_complete = true;
                    self.ppu.latch_affine_frame();
                }
                if new_line < ppu::VDRAW as u16 && new_line != 0 {
                    self.ppu.step_affine_line();
                }
            }
        }
    }

    // --- Timer stepping ---------------------------------------------------
    fn step_timers(&mut self, cycles: u32) {
        let mut prev_overflows = 0u32;
        for i in 0..4 {
            let mut overflows = 0u32;
            let irq;
            {
                let t = &mut self.timers.t[i];
                if !t.enabled() {
                    prev_overflows = 0;
                    continue;
                }
                if t.cascade() && i > 0 {
                    // Tick once per overflow of the previous timer.
                    if prev_overflows > 0 {
                        let mut c = t.counter as u32 + prev_overflows;
                        while c > 0xFFFF {
                            overflows += 1;
                            c -= 0x10000 - t.reload as u32;
                        }
                        t.counter = c as u16;
                    }
                } else {
                    let shift = t.prescaler_shift();
                    t.prescaler_cycles += cycles;
                    let ticks = t.prescaler_cycles >> shift;
                    t.prescaler_cycles &= (1 << shift) - 1;
                    if ticks > 0 {
                        let mut c = t.counter as u32 + ticks;
                        while c > 0xFFFF {
                            overflows += 1;
                            c -= 0x10000 - t.reload as u32;
                        }
                        t.counter = c as u16;
                    }
                }
                irq = t.irq();
            }
            prev_overflows = overflows;
            if overflows > 0 {
                if irq {
                    self.if_ |= IRQ_TIMER0 << i;
                }
                for _ in 0..overflows {
                    self.on_timer_overflow(i);
                }
            }
        }
    }

    fn on_timer_overflow(&mut self, timer: usize) {
        // Direct Sound A/B are clocked by timer 0 or 1 (soundcnt_h bits 10/14).
        let h = self.apu.soundcnt_h;
        let a_timer = ((h >> 10) & 1) as usize;
        let b_timer = ((h >> 14) & 1) as usize;
        if timer == a_timer {
            self.apu.fifo_a.pop();
            if self.apu.fifo_a.len <= 16 {
                self.fifo_a_request = true;
            }
        }
        if timer == b_timer {
            self.apu.fifo_b.pop();
            if self.apu.fifo_b.len <= 16 {
                self.fifo_b_request = true;
            }
        }
    }

    // --- DMA triggers -----------------------------------------------------
    fn trigger_dma_vblank(&mut self) {
        for i in 0..4 {
            if self.dma.ch[i].enabled() && self.dma.ch[i].timing() == 1 {
                self.dma_pending |= 1 << i;
            }
        }
    }
    fn trigger_dma_hblank(&mut self) {
        for i in 0..4 {
            if self.dma.ch[i].enabled() && self.dma.ch[i].timing() == 2 {
                self.dma_pending |= 1 << i;
            }
        }
    }

    // --- IRQ --------------------------------------------------------------
    #[inline]
    pub fn irq_active(&self) -> bool {
        self.ime && (self.ie & self.if_) != 0
    }

    // --- Raw memory helpers ----------------------------------------------
    #[inline]
    fn vram_index(addr: u32) -> usize {
        let mut a = addr & 0x1FFFF;
        if a >= 0x18000 {
            a -= 0x8000;
        }
        a as usize
    }

    // 8/16/32-bit reads from memory regions (no timing).
    pub fn read8_raw(&mut self, addr: u32) -> u8 {
        let region = (addr >> 24) & 0xF;
        match region {
            0x0 => {
                if addr < 0x4000 {
                    self.bios[addr as usize]
                } else {
                    (self.open_bus >> ((addr & 3) * 8)) as u8
                }
            }
            0x2 => self.ewram[(addr as usize) & 0x3FFFF],
            0x3 => self.iwram[(addr as usize) & 0x7FFF],
            0x4 => self.io_read8(addr),
            0x5 => self.ppu.palette[(addr as usize) & 0x3FF],
            0x6 => self.ppu.vram[Self::vram_index(addr)],
            0x7 => self.ppu.oam[(addr as usize) & 0x3FF],
            0xD if self.save.is_eeprom() => self.save.eeprom_read_bit(),
            0x8..=0xD => {
                let off = (addr & 0x01FF_FFFF) as usize;
                if off < self.rom.len() { self.rom[off] } else { (addr >> 1) as u8 }
            }
            0xE | 0xF => self.save.read8(addr),
            _ => (self.open_bus >> ((addr & 3) * 8)) as u8,
        }
    }

    pub fn read16_raw(&mut self, addr: u32) -> u16 {
        let addr = addr & !1;
        let region = (addr >> 24) & 0xF;
        match region {
            0x0 => {
                if addr < 0x4000 {
                    u16::from_le_bytes([self.bios[addr as usize], self.bios[addr as usize + 1]])
                } else {
                    (self.open_bus >> ((addr & 2) * 8)) as u16
                }
            }
            0x2 => {
                let i = (addr as usize) & 0x3FFFF;
                u16::from_le_bytes([self.ewram[i], self.ewram[i + 1]])
            }
            0x3 => {
                let i = (addr as usize) & 0x7FFF;
                u16::from_le_bytes([self.iwram[i], self.iwram[i + 1]])
            }
            0x4 => self.io_read16(addr),
            0x5 => {
                let i = (addr as usize) & 0x3FF;
                u16::from_le_bytes([self.ppu.palette[i], self.ppu.palette[i + 1]])
            }
            0x6 => {
                let i = Self::vram_index(addr);
                u16::from_le_bytes([self.ppu.vram[i], self.ppu.vram[i + 1]])
            }
            0x7 => {
                let i = (addr as usize) & 0x3FF;
                u16::from_le_bytes([self.ppu.oam[i], self.ppu.oam[i + 1]])
            }
            0xD if self.save.is_eeprom() => self.save.eeprom_read_bit() as u16,
            0x8..=0xD => {
                let off = (addr & 0x01FF_FFFF) as usize;
                if off + 1 < self.rom.len() {
                    u16::from_le_bytes([self.rom[off], self.rom[off + 1]])
                } else {
                    (addr >> 1) as u16
                }
            }
            0xE | 0xF => {
                let b = self.save.read8(addr);
                u16::from_le_bytes([b, b])
            }
            _ => (self.open_bus >> ((addr & 2) * 8)) as u16,
        }
    }

    pub fn read32_raw(&mut self, addr: u32) -> u32 {
        let addr = addr & !3;
        (self.read16_raw(addr) as u32) | ((self.read16_raw(addr + 2) as u32) << 16)
    }

    pub fn write8_raw(&mut self, addr: u32, val: u8) {
        let region = (addr >> 24) & 0xF;
        match region {
            0x2 => self.ewram[(addr as usize) & 0x3FFFF] = val,
            0x3 => self.iwram[(addr as usize) & 0x7FFF] = val,
            0x4 => self.io_write8(addr, val),
            0x5 => {
                // 8-bit write to palette: duplicate to halfword.
                let i = (addr as usize) & 0x3FE;
                self.ppu.palette[i] = val;
                self.ppu.palette[i + 1] = val;
            }
            0x6 => {
                // 8-bit VRAM write: duplicate into halfword if in BG area; else ignore.
                let mode = (self.ppu.dispcnt & 0x7) as u32;
                let obj_base = if mode >= 3 { 0x14000 } else { 0x10000 };
                let i = Self::vram_index(addr) & !1;
                if i < obj_base {
                    self.ppu.vram[i] = val;
                    self.ppu.vram[i + 1] = val;
                }
            }
            0x7 => { /* OAM ignores byte writes */ }
            0xD if self.save.is_eeprom() => {
                let bits = self.eeprom_addr_bits;
                self.save.eeprom_write_bit(val & 1, bits);
            }
            0xE | 0xF => self.save.write8(addr, val),
            _ => {}
        }
    }

    pub fn write16_raw(&mut self, addr: u32, val: u16) {
        let addr = addr & !1;
        let region = (addr >> 24) & 0xF;
        let [lo, hi] = val.to_le_bytes();
        match region {
            0x2 => {
                let i = (addr as usize) & 0x3FFFF;
                self.ewram[i] = lo;
                self.ewram[i + 1] = hi;
            }
            0x3 => {
                let i = (addr as usize) & 0x7FFF;
                self.iwram[i] = lo;
                self.iwram[i + 1] = hi;
            }
            0x4 => self.io_write16(addr, val),
            0x5 => {
                let i = (addr as usize) & 0x3FF;
                self.ppu.palette[i] = lo;
                self.ppu.palette[i + 1] = hi;
            }
            0x6 => {
                let i = Self::vram_index(addr);
                self.ppu.vram[i] = lo;
                self.ppu.vram[i + 1] = hi;
            }
            0x7 => {
                let i = (addr as usize) & 0x3FF;
                self.ppu.oam[i] = lo;
                self.ppu.oam[i + 1] = hi;
            }
            0xD if self.save.is_eeprom() => {
                let bits = self.eeprom_addr_bits;
                self.save.eeprom_write_bit((val & 1) as u8, bits);
            }
            0xE | 0xF => {
                let b = (val.rotate_right(((addr & 1) * 8) as u32)) as u8;
                self.save.write8(addr, b);
            }
            _ => {}
        }
    }

    pub fn write32_raw(&mut self, addr: u32, val: u32) {
        let addr = addr & !3;
        self.write16_raw(addr, val as u16);
        self.write16_raw(addr + 2, (val >> 16) as u16);
    }
}

// Bus trait impl: timed accesses. Access type is provided by the CPU, which
// knows its own sequential/non-sequential access pattern.
impl Bus for SysBus {
    fn read8(&mut self, addr: u32, access: Access) -> u8 {
        let c = self.access_cycles(addr, 1, access);
        self.tick(c);
        let v = self.read8_raw(addr);
        self.open_bus = (self.open_bus & !0xFF) | v as u32;
        v
    }
    fn read16(&mut self, addr: u32, access: Access) -> u16 {
        let c = self.access_cycles(addr, 2, access);
        self.tick(c);
        let v = self.read16_raw(addr);
        self.open_bus = v as u32 | ((v as u32) << 16);
        v
    }
    fn read32(&mut self, addr: u32, access: Access) -> u32 {
        let c = self.access_cycles(addr, 4, access);
        self.tick(c);
        let v = self.read32_raw(addr);
        self.open_bus = v;
        v
    }
    fn write8(&mut self, addr: u32, val: u8, access: Access) {
        let c = self.access_cycles(addr, 1, access);
        self.tick(c);
        self.write8_raw(addr, val);
    }
    fn write16(&mut self, addr: u32, val: u16, access: Access) {
        let c = self.access_cycles(addr, 2, access);
        self.tick(c);
        self.write16_raw(addr, val);
    }
    fn write32(&mut self, addr: u32, val: u32, access: Access) {
        let c = self.access_cycles(addr, 4, access);
        self.tick(c);
        self.write32_raw(addr, val);
    }
    fn idle(&mut self, cycles: u32) {
        self.tick(cycles);
    }
    fn irq_pending(&self) -> bool {
        self.irq_active()
    }
}
