//! Sound register read/write decode mapping to APU channel state.

use crate::bus::SysBus;

impl SysBus {
    pub fn sound_read(&self, reg: u32) -> u16 {
        // PSG registers 0x60-0x81 read back as 0 while the master enable is off.
        if !self.apu.master_enable && (0x060..=0x081).contains(&reg) {
            return 0;
        }
        let a = &self.apu;
        match reg {
            0x060 => {
                // NR10 sweep
                ((a.ch1.sweep_shift as u16)
                    | ((a.ch1.sweep_dir as u16) << 3)
                    | ((a.ch1.sweep_period as u16) << 4)) as u16
            }
            0x062 => {
                ((a.ch1.duty as u16) << 6)
                    | ((a.ch1.env_period as u16) << 8)
                    | ((a.ch1.env_dir as u16) << 11)
                    | ((a.ch1.env_initial as u16) << 12)
            }
            0x064 => ((a.ch1.length_enable as u16) << 14),
            0x068 => {
                ((a.ch2.duty as u16) << 6)
                    | ((a.ch2.env_period as u16) << 8)
                    | ((a.ch2.env_dir as u16) << 11)
                    | ((a.ch2.env_initial as u16) << 12)
            }
            0x06C => ((a.ch2.length_enable as u16) << 14),
            0x070 => {
                ((a.wave.bank_mode as u16) << 5)
                    | ((a.wave.bank as u16) << 6)
                    | ((a.wave.dac_on as u16) << 7)
            }
            0x072 => {
                ((a.wave.volume as u16) << 13) | ((a.wave.force_vol as u16) << 15)
            }
            0x074 => ((a.wave.length_enable as u16) << 14),
            0x078 => {
                ((a.noise.env_period as u16) << 8)
                    | ((a.noise.env_dir as u16) << 11)
                    | ((a.noise.env_initial as u16) << 12)
            }
            0x07C => {
                (a.noise.divisor as u16)
                    | ((a.noise.width7 as u16) << 3)
                    | ((a.noise.shift as u16) << 4)
            }
            0x084 => {
                let mut v = (a.master_enable as u16) << 7;
                if a.ch1.enabled { v |= 1; }
                if a.ch2.enabled { v |= 2; }
                if a.wave.enabled { v |= 4; }
                if a.noise.enabled { v |= 8; }
                v
            }
            _ => 0,
        }
    }

    pub fn sound_write(&mut self, reg: u32, val: u16) {
        // While the master enable (SOUNDCNT_X bit7) is off, the PSG registers
        // 0x60-0x81 are reset to 0 and cannot be written (hardware). SOUNDCNT_H/X,
        // SOUNDBIAS and wave RAM are unaffected.
        if !self.apu.master_enable && (0x060..=0x081).contains(&reg) {
            return;
        }
        match reg {
            0x060 => {
                let c = &mut self.apu.ch1;
                c.sweep_shift = (val & 0x7) as u8;
                c.sweep_dir = val & 0x8 != 0;
                c.sweep_period = ((val >> 4) & 0x7) as u8;
            }
            0x062 => {
                let c = &mut self.apu.ch1;
                c.length = (val & 0x3F) as u8;
                c.length_counter = 64 - (val & 0x3F);
                c.duty = ((val >> 6) & 0x3) as u8;
                c.env_period = ((val >> 8) & 0x7) as u8;
                c.env_dir = val & 0x800 != 0;
                c.env_initial = ((val >> 12) & 0xF) as u8;
                // DAC off (vol 0 + decrease) immediately disables the channel.
                if c.env_initial == 0 && !c.env_dir { c.enabled = false; }
            }
            0x064 => {
                let c = &mut self.apu.ch1;
                c.freq = val & 0x7FF;
                c.length_enable = val & 0x4000 != 0;
                if val & 0x8000 != 0 {
                    Self::trigger_square1(&mut self.apu);
                }
            }
            0x068 => {
                let c = &mut self.apu.ch2;
                c.length = (val & 0x3F) as u8;
                c.length_counter = 64 - (val & 0x3F);
                c.duty = ((val >> 6) & 0x3) as u8;
                c.env_period = ((val >> 8) & 0x7) as u8;
                c.env_dir = val & 0x800 != 0;
                c.env_initial = ((val >> 12) & 0xF) as u8;
                if c.env_initial == 0 && !c.env_dir { c.enabled = false; }
            }
            0x06C => {
                let c = &mut self.apu.ch2;
                c.freq = val & 0x7FF;
                c.length_enable = val & 0x4000 != 0;
                if val & 0x8000 != 0 {
                    Self::trigger_square2(&mut self.apu);
                }
            }
            0x070 => {
                let w = &mut self.apu.wave;
                w.bank_mode = val & 0x20 != 0;
                w.bank = ((val >> 6) & 1) as usize;
                w.dac_on = val & 0x80 != 0;
                if !w.dac_on { w.enabled = false; }
            }
            0x072 => {
                let w = &mut self.apu.wave;
                w.length_counter = 256 - (val & 0xFF);
                w.volume = ((val >> 13) & 0x3) as u8;
                w.force_vol = val & 0x8000 != 0;
            }
            0x074 => {
                let w = &mut self.apu.wave;
                w.freq = val & 0x7FF;
                w.length_enable = val & 0x4000 != 0;
                if val & 0x8000 != 0 && w.dac_on {
                    w.enabled = true;
                    w.pos = 0;
                    if w.length_counter == 0 { w.length_counter = 256; }
                }
            }
            0x078 => {
                let n = &mut self.apu.noise;
                n.length_counter = 64 - (val & 0x3F);
                n.env_period = ((val >> 8) & 0x7) as u8;
                n.env_dir = val & 0x800 != 0;
                n.env_initial = ((val >> 12) & 0xF) as u8;
                if n.env_initial == 0 && !n.env_dir { n.enabled = false; }
            }
            0x07C => {
                let n = &mut self.apu.noise;
                n.divisor = (val & 0x7) as u8;
                n.width7 = val & 0x8 != 0;
                n.shift = ((val >> 4) & 0xF) as u8;
                n.length_enable = val & 0x4000 != 0;
                if val & 0x8000 != 0 {
                    Self::trigger_noise(&mut self.apu);
                }
            }
            0x082 => {
                // Bits 11/15 are write-only FIFO-reset triggers; they read back
                // as 0 (hardware). Storing them would make a read-modify-write of
                // SOUNDCNT_H re-trigger the reset on every write.
                self.apu.soundcnt_h = val & !0x8800;
                if val & 0x0800 != 0 { self.apu.fifo_a.clear(); }
                if val & 0x8000 != 0 { self.apu.fifo_b.clear(); }
            }
            0x084 => {
                let en = val & 0x80 != 0;
                self.apu.master_enable = en;
                if !en {
                    // Master off disables the PSG channels (their status bits read
                    // 0 and the registers reset); DS FIFOs are separate.
                    self.apu.ch1.enabled = false;
                    self.apu.ch2.enabled = false;
                    self.apu.wave.enabled = false;
                    self.apu.noise.enabled = false;
                }
            }
            _ => {}
        }
    }

    fn trigger_square1(a: &mut crate::apu::Apu) {
        let c = &mut a.ch1;
        // Trigger only enables the channel if the DAC is on (vol != 0 or increase).
        c.enabled = c.env_initial != 0 || c.env_dir;
        if c.length_counter == 0 { c.length_counter = 64; }
        c.env_vol = c.env_initial;
        c.env_timer = c.env_period;
        c.timer = ((2048 - c.freq as i32) * 16).max(1);
        // sweep init
        c.sweep_shadow = c.freq;
        c.sweep_timer = if c.sweep_period == 0 { 8 } else { c.sweep_period };
        c.sweep_enable = c.sweep_period != 0 || c.sweep_shift != 0;
    }
    fn trigger_square2(a: &mut crate::apu::Apu) {
        let c = &mut a.ch2;
        c.enabled = c.env_initial != 0 || c.env_dir;
        if c.length_counter == 0 { c.length_counter = 64; }
        c.env_vol = c.env_initial;
        c.env_timer = c.env_period;
        c.timer = ((2048 - c.freq as i32) * 16).max(1);
    }
    fn trigger_noise(a: &mut crate::apu::Apu) {
        let n = &mut a.noise;
        n.enabled = n.env_initial != 0 || n.env_dir;
        if n.length_counter == 0 { n.length_counter = 64; }
        n.env_vol = n.env_initial;
        n.env_timer = n.env_period;
        n.lfsr = if n.width7 { 0x7F } else { 0x7FFF };
    }
}
