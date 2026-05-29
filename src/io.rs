//! Memory-mapped I/O register read/write handlers (0x0400_0000..0x0400_03FF).

use crate::bus::SysBus;

impl SysBus {
    pub fn io_read8(&mut self, addr: u32) -> u8 {
        let hw = self.io_read16(addr & !1);
        if addr & 1 == 0 { hw as u8 } else { (hw >> 8) as u8 }
    }

    pub fn io_read16(&mut self, addr: u32) -> u16 {
        let reg = addr & 0xFFFF;
        match reg {
            0x000 => self.ppu.dispcnt,
            0x002 => self.ppu.green_swap,
            0x004 => self.ppu.dispstat,
            0x006 => self.ppu.vcount,
            // BG0/1 are text BGs: bit 13 (affine display-area overflow) is unused
            // and reads back as 0. BG2/3 keep it.
            0x008 => self.ppu.bgcnt[0] & 0xDFFF,
            0x00A => self.ppu.bgcnt[1] & 0xDFFF,
            0x00C => self.ppu.bgcnt[2],
            0x00E => self.ppu.bgcnt[3],
            // Unused high bits read back as 0 (verified vs oracle).
            0x048 => self.ppu.winin & 0x3F3F,
            0x04A => self.ppu.winout & 0x3F3F,
            0x050 => self.ppu.bldcnt & 0x3FFF,
            0x052 => self.ppu.bldalpha & 0x1F1F,
            // Sound
            0x060 => self.sound_read(0x060),
            0x062 => self.sound_read(0x062),
            0x064 => self.sound_read(0x064),
            0x068 => self.sound_read(0x068),
            0x06C => self.sound_read(0x06C),
            0x070 => self.sound_read(0x070),
            0x072 => self.sound_read(0x072),
            0x074 => self.sound_read(0x074),
            0x078 => self.sound_read(0x078),
            0x07C => self.sound_read(0x07C),
            // SOUNDCNT_L is in the 0x60-0x81 master-gated range: reads 0 while off.
            0x080 => if self.apu.master_enable { self.apu.soundcnt_l } else { 0 },
            0x082 => self.apu.soundcnt_h,
            0x084 => self.sound_read(0x084),
            // Bits 0,10-13 unused (read 0); bits 1-9 bias, 14-15 resolution.
            0x088 => self.apu.soundbias & 0xC3FE,
            0x090..=0x09F => {
                let i = (reg - 0x090) as usize;
                let b = self.apu.wave_access_bank() * 16;
                u16::from_le_bytes([self.apu.wave.ram[b + i], self.apu.wave.ram[b + i + 1]])
            }
            // DMA control (only CNT_H readable)
            0x0BA => self.dma.ch[0].control,
            0x0C6 => self.dma.ch[1].control,
            0x0D2 => self.dma.ch[2].control,
            0x0DE => self.dma.ch[3].control,
            // Timers
            0x100 => self.timers.t[0].counter,
            0x102 => self.timers.t[0].control,
            0x104 => self.timers.t[1].counter,
            0x106 => self.timers.t[1].control,
            0x108 => self.timers.t[2].counter,
            0x10A => self.timers.t[2].control,
            0x10C => self.timers.t[3].counter,
            0x10E => self.timers.t[3].control,
            0x130 => {
                #[cfg(feature = "trace")] eprintln!("KEYINPUT read -> {:04x} @cyc {}", self.keyinput, self.sched.now);
                self.keyinput
            }
            0x132 => self.keycnt,
            0x200 => self.ie,
            0x202 => self.if_,
            0x204 => self.waitcnt,
            0x208 => self.ime as u16,
            0x300 => self.postflg as u16,
            _ => (self.open_bus >> ((addr & 2) * 8)) as u16,
        }
    }

    pub fn io_write8(&mut self, addr: u32, val: u8) {
        let reg = addr & 0xFFFF;
        // Some registers are byte-sensitive (HALTCNT, IF, FIFO).
        match reg {
            0x301 => {
                // HALTCNT
                self.haltcnt = val;
                if val & 0x80 == 0 {
                    self.halted = true; // Halt
                }
            }
            0x300 => { self.postflg = val; }
            // FIFO byte writes.
            0x0A0..=0x0A3 => self.apu.fifo_a.push(val as i8),
            0x0A4..=0x0A7 => self.apu.fifo_b.push(val as i8),
            _ => {
                // Read-modify-write the halfword.
                let cur = self.io_read16(addr & !1);
                let new = if addr & 1 == 0 {
                    (cur & 0xFF00) | val as u16
                } else {
                    (cur & 0x00FF) | ((val as u16) << 8)
                };
                self.io_write16(addr & !1, new);
            }
        }
    }

    pub fn io_write16(&mut self, addr: u32, val: u16) {
        let reg = addr & 0xFFFF;
        match reg {
            0x000 => self.ppu.dispcnt = val,
            0x002 => self.ppu.green_swap = val,
            0x004 => {
                // Only bits 3-5 (IRQ enables) and 8-15 (vcount) are writable.
                self.ppu.dispstat = (self.ppu.dispstat & 0x7) | (val & 0xFF38);
            }
            0x006 => {} // VCOUNT read-only
            0x008 => self.ppu.bgcnt[0] = val,
            0x00A => self.ppu.bgcnt[1] = val,
            0x00C => self.ppu.bgcnt[2] = val,
            0x00E => self.ppu.bgcnt[3] = val,
            0x010 => self.ppu.bghofs[0] = val & 0x1FF,
            0x012 => self.ppu.bgvofs[0] = val & 0x1FF,
            0x014 => self.ppu.bghofs[1] = val & 0x1FF,
            0x016 => self.ppu.bgvofs[1] = val & 0x1FF,
            0x018 => self.ppu.bghofs[2] = val & 0x1FF,
            0x01A => self.ppu.bgvofs[2] = val & 0x1FF,
            0x01C => { self.ppu.bghofs[3] = val & 0x1FF; #[cfg(feature="trace")] eprintln!("BG3HOFS={} vc={} dot={}", val&0x1FF, self.ppu.vcount, self.ppu.dot); }
            0x01E => self.ppu.bgvofs[3] = val & 0x1FF,
            0x020 => self.ppu.bg_pa[0] = val as i16,
            0x022 => self.ppu.bg_pb[0] = val as i16,
            0x024 => self.ppu.bg_pc[0] = val as i16,
            0x026 => self.ppu.bg_pd[0] = val as i16,
            0x028 => { self.ppu.bg_x[0] = sext28((self.ppu.bg_x[0] as u32 & 0xFFFF0000) | val as u32); self.ppu.bg_x_latch[0] = self.ppu.bg_x[0]; }
            0x02A => { self.ppu.bg_x[0] = sext28((self.ppu.bg_x[0] as u32 & 0xFFFF) | ((val as u32) << 16)); self.ppu.bg_x_latch[0] = self.ppu.bg_x[0]; }
            0x02C => { self.ppu.bg_y[0] = sext28((self.ppu.bg_y[0] as u32 & 0xFFFF0000) | val as u32); self.ppu.bg_y_latch[0] = self.ppu.bg_y[0]; }
            0x02E => { self.ppu.bg_y[0] = sext28((self.ppu.bg_y[0] as u32 & 0xFFFF) | ((val as u32) << 16)); self.ppu.bg_y_latch[0] = self.ppu.bg_y[0]; }
            0x030 => self.ppu.bg_pa[1] = val as i16,
            0x032 => self.ppu.bg_pb[1] = val as i16,
            0x034 => self.ppu.bg_pc[1] = val as i16,
            0x036 => self.ppu.bg_pd[1] = val as i16,
            0x038 => { self.ppu.bg_x[1] = sext28((self.ppu.bg_x[1] as u32 & 0xFFFF0000) | val as u32); self.ppu.bg_x_latch[1] = self.ppu.bg_x[1]; }
            0x03A => { self.ppu.bg_x[1] = sext28((self.ppu.bg_x[1] as u32 & 0xFFFF) | ((val as u32) << 16)); self.ppu.bg_x_latch[1] = self.ppu.bg_x[1]; }
            0x03C => { self.ppu.bg_y[1] = sext28((self.ppu.bg_y[1] as u32 & 0xFFFF0000) | val as u32); self.ppu.bg_y_latch[1] = self.ppu.bg_y[1]; }
            0x03E => { self.ppu.bg_y[1] = sext28((self.ppu.bg_y[1] as u32 & 0xFFFF) | ((val as u32) << 16)); self.ppu.bg_y_latch[1] = self.ppu.bg_y[1]; }
            0x040 => self.ppu.winh[0] = val,
            0x042 => self.ppu.winh[1] = val,
            0x044 => self.ppu.winv[0] = val,
            0x046 => self.ppu.winv[1] = val,
            0x048 => self.ppu.winin = val,
            0x04A => self.ppu.winout = val,
            0x04C => self.ppu.mosaic = val,
            0x050 => self.ppu.bldcnt = val,
            0x052 => self.ppu.bldalpha = val,
            0x054 => self.ppu.bldy = val,
            // Sound channel registers.
            0x060 | 0x062 | 0x064 | 0x066 | 0x068 | 0x06C
            | 0x070 | 0x072 | 0x074 | 0x078 | 0x07C => self.sound_write(reg, val),
            0x080 => { if self.apu.master_enable { self.apu.soundcnt_l = val; } }
            0x082 => self.sound_write(0x082, val),
            0x084 => self.sound_write(0x084, val),
            0x088 => self.apu.soundbias = val,
            0x090..=0x09F => {
                let i = (reg - 0x090) as usize;
                let b = self.apu.wave_access_bank() * 16;
                let [lo, hi] = val.to_le_bytes();
                self.apu.wave.ram[b + i] = lo;
                self.apu.wave.ram[b + i + 1] = hi;
            }
            0x0A0 | 0x0A2 => {
                let [lo, hi] = val.to_le_bytes();
                self.apu.fifo_a.push(lo as i8);
                self.apu.fifo_a.push(hi as i8);
            }
            0x0A4 | 0x0A6 => {
                let [lo, hi] = val.to_le_bytes();
                self.apu.fifo_b.push(lo as i8);
                self.apu.fifo_b.push(hi as i8);
            }
            // DMA registers.
            0x0B0 => self.dma.ch[0].src = (self.dma.ch[0].src & 0xFFFF0000) | val as u32,
            0x0B2 => self.dma.ch[0].src = (self.dma.ch[0].src & 0xFFFF) | ((val as u32) << 16),
            0x0B4 => self.dma.ch[0].dst = (self.dma.ch[0].dst & 0xFFFF0000) | val as u32,
            0x0B6 => self.dma.ch[0].dst = (self.dma.ch[0].dst & 0xFFFF) | ((val as u32) << 16),
            0x0B8 => self.dma.ch[0].count = val as u32,
            0x0BA => self.dma_control_write(0, val),
            0x0BC => self.dma.ch[1].src = (self.dma.ch[1].src & 0xFFFF0000) | val as u32,
            0x0BE => self.dma.ch[1].src = (self.dma.ch[1].src & 0xFFFF) | ((val as u32) << 16),
            0x0C0 => self.dma.ch[1].dst = (self.dma.ch[1].dst & 0xFFFF0000) | val as u32,
            0x0C2 => self.dma.ch[1].dst = (self.dma.ch[1].dst & 0xFFFF) | ((val as u32) << 16),
            0x0C4 => self.dma.ch[1].count = val as u32,
            0x0C6 => self.dma_control_write(1, val),
            0x0C8 => self.dma.ch[2].src = (self.dma.ch[2].src & 0xFFFF0000) | val as u32,
            0x0CA => self.dma.ch[2].src = (self.dma.ch[2].src & 0xFFFF) | ((val as u32) << 16),
            0x0CC => self.dma.ch[2].dst = (self.dma.ch[2].dst & 0xFFFF0000) | val as u32,
            0x0CE => self.dma.ch[2].dst = (self.dma.ch[2].dst & 0xFFFF) | ((val as u32) << 16),
            0x0D0 => self.dma.ch[2].count = val as u32,
            0x0D2 => self.dma_control_write(2, val),
            0x0D4 => self.dma.ch[3].src = (self.dma.ch[3].src & 0xFFFF0000) | val as u32,
            0x0D6 => self.dma.ch[3].src = (self.dma.ch[3].src & 0xFFFF) | ((val as u32) << 16),
            0x0D8 => self.dma.ch[3].dst = (self.dma.ch[3].dst & 0xFFFF0000) | val as u32,
            0x0DA => self.dma.ch[3].dst = (self.dma.ch[3].dst & 0xFFFF) | ((val as u32) << 16),
            0x0DC => self.dma.ch[3].count = val as u32,
            0x0DE => self.dma_control_write(3, val),
            // Timers.
            0x100 => self.timers.t[0].reload = val,
            0x102 => self.timer_control_write(0, val),
            0x104 => self.timers.t[1].reload = val,
            0x106 => self.timer_control_write(1, val),
            0x108 => self.timers.t[2].reload = val,
            0x10A => self.timer_control_write(2, val),
            0x10C => self.timers.t[3].reload = val,
            0x10E => self.timer_control_write(3, val),
            0x130 => {} // KEYINPUT read-only
            0x132 => { self.keycnt = val; self.check_keypad_irq(); }
            0x200 => self.ie = val,
            0x202 => self.if_ &= !val, // writing 1 acks
            0x204 => { self.waitcnt = val; self.update_waitstates();
                #[cfg(feature = "trace")] eprintln!("WAITCNT <- {:04x} @cyc {}", val, self.sched.now); }
            0x208 => self.ime = val & 1 != 0,
            0x300 => { self.postflg = (val & 1) as u8; if val & 0x8000 != 0 { self.halted = true; } }
            0x800 | 0x802 => {
                if reg == 0x800 {
                    self.memctrl = (self.memctrl & 0xFFFF0000) | val as u32;
                } else {
                    self.memctrl = (self.memctrl & 0xFFFF) | ((val as u32) << 16);
                }
                self.update_ewram_wait();
                #[cfg(feature = "trace")] eprintln!("MEMCTRL <- {:08x} @cyc {}", self.memctrl, self.sched.now);
            }
            _ => {}
        }
    }

    fn dma_control_write(&mut self, ch: usize, val: u16) {
        let was_enabled = self.dma.ch[ch].enabled();
        self.dma.ch[ch].control = val;
        let now_enabled = self.dma.ch[ch].enabled();
        if now_enabled && !was_enabled {
            // Latch src/dst/count.
            let c = &mut self.dma.ch[ch];
            c.cur_src = c.src;
            c.cur_dst = c.dst;
            c.cur_count = if c.count == 0 {
                if ch == 3 { 0x10000 } else { 0x4000 }
            } else {
                c.count
            };
            c.active = true;
            // Immediate timing => run now.
            if c.timing() == 0 {
                self.dma_pending |= 1 << ch;
            }
        }
        if !now_enabled {
            self.dma.ch[ch].active = false;
        }
    }

    fn timer_control_write(&mut self, ch: usize, val: u16) {
        let was_enabled = self.timers.t[ch].enabled();
        let t = &mut self.timers.t[ch];
        let now_enabled = val & 0x80 != 0;
        if now_enabled && !was_enabled {
            t.counter = t.reload;
            t.prescaler_cycles = 0;
        }
        t.control = val;
        #[cfg(feature = "trace")]
        if now_enabled {
            eprintln!("TIMER{} reload={:04x} ctrl={:04x} prescale={} cascade={} irq={} @cyc {}",
                ch, t.reload, val, val & 3, (val >> 2) & 1, (val >> 6) & 1, self.sched.now);
        }
        self.timers.refresh_active();
    }

}

#[inline]
fn sext28(v: u32) -> i32 {
    ((v << 4) as i32) >> 4
}
