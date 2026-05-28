//! Audio Processing Unit — 4 PSG channels + 2 Direct Sound FIFO channels.

pub const SAMPLE_RATE: u32 = 32768;
// System clock 16.78 MHz; cycles per output sample at 32768 Hz.
pub const CYCLES_PER_SAMPLE: u32 = 16_777_216 / SAMPLE_RATE; // 512

const DUTY: [[u8; 8]; 4] = [
    [0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1, 1, 1],
    [0, 1, 1, 1, 1, 1, 1, 0],
];

#[derive(Clone, Default)]
pub struct Square {
    pub enabled: bool,
    pub freq: u16,        // 11-bit
    pub duty: u8,
    pub phase: u8,        // 0..7
    pub timer: i32,       // counts down clocks
    pub length: u8,
    pub length_enable: bool,
    pub length_counter: u16,
    pub env_vol: u8,
    pub env_initial: u8,
    pub env_dir: bool,    // true = increase
    pub env_period: u8,
    pub env_timer: u8,
    // sweep (ch1 only)
    pub sweep_period: u8,
    pub sweep_dir: bool,  // true = decrease
    pub sweep_shift: u8,
    pub sweep_timer: u8,
    pub sweep_enable: bool,
    pub sweep_shadow: u16,
}

#[derive(Clone)]
pub struct Wave {
    pub enabled: bool,
    pub dac_on: bool,
    pub freq: u16,
    pub timer: i32,
    pub pos: usize,
    pub length_enable: bool,
    pub length_counter: u16,
    pub volume: u8,    // 0=mute,1=100,2=50,3=25
    pub force_vol: bool, // 75%
    pub bank_mode: bool, // true=64 samples
    pub bank: usize,
    pub ram: [u8; 32],   // two banks of 16 bytes (32 samples each nibble)
    pub sample: u8,
}

impl Default for Wave {
    fn default() -> Self {
        Wave {
            enabled: false, dac_on: false, freq: 0, timer: 0, pos: 0,
            length_enable: false, length_counter: 0, volume: 0, force_vol: false,
            bank_mode: false, bank: 0, ram: [0; 32], sample: 0,
        }
    }
}

#[derive(Clone, Default)]
pub struct Noise {
    pub enabled: bool,
    pub timer: i32,
    pub lfsr: u16,
    pub width7: bool,
    pub divisor: u8,
    pub shift: u8,
    pub length_enable: bool,
    pub length_counter: u16,
    pub env_vol: u8,
    pub env_initial: u8,
    pub env_dir: bool,
    pub env_period: u8,
    pub env_timer: u8,
    pub sample: u8,
}

#[derive(Clone)]
pub struct Fifo {
    pub data: [i8; 32],
    pub head: usize,
    pub tail: usize,
    pub len: usize,
    pub current: i8,
}

impl Default for Fifo {
    fn default() -> Self {
        Fifo { data: [0; 32], head: 0, tail: 0, len: 0, current: 0 }
    }
}

impl Fifo {
    pub fn push(&mut self, v: i8) {
        if self.len < 32 {
            self.data[self.tail] = v;
            self.tail = (self.tail + 1) & 31;
            self.len += 1;
        }
    }
    pub fn pop(&mut self) {
        if self.len > 0 {
            self.current = self.data[self.head];
            self.head = (self.head + 1) & 31;
            self.len -= 1;
        }
    }
    pub fn clear(&mut self) {
        self.head = 0;
        self.tail = 0;
        self.len = 0;
        self.current = 0;
    }
}

#[derive(Clone)]
pub struct Apu {
    pub ch1: Square,
    pub ch2: Square,
    pub wave: Wave,
    pub noise: Noise,
    pub fifo_a: Fifo,
    pub fifo_b: Fifo,

    pub soundcnt_l: u16, // 0x80 NR50/51 PSG control
    pub soundcnt_h: u16, // 0x82 DMA sound control
    pub soundcnt_x: u16, // 0x84 master enable
    pub soundbias: u16,  // 0x88

    pub frame_seq: u8,        // 512Hz frame sequencer step
    pub frame_seq_timer: i32, // cycles toward next 512Hz step

    pub sample_timer: i32,
    pub buffer: Vec<i16>,     // interleaved stereo output

    pub master_enable: bool,
}

impl Apu {
    pub fn new() -> Self {
        Apu {
            ch1: Square::default(),
            ch2: Square::default(),
            wave: Wave::default(),
            noise: Noise { lfsr: 0x7FFF, ..Default::default() },
            fifo_a: Fifo::default(),
            fifo_b: Fifo::default(),
            soundcnt_l: 0,
            soundcnt_h: 0,
            soundcnt_x: 0,
            soundbias: 0x200,
            frame_seq: 0,
            frame_seq_timer: 0,
            sample_timer: 0,
            buffer: Vec::with_capacity(2048),
            master_enable: false,
        }
    }

    pub fn reset(&mut self) {
        let buf = std::mem::take(&mut self.buffer);
        *self = Apu::new();
        self.buffer = buf;
        self.buffer.clear();
    }

    /// Output sample rate in Hz, determined by SOUNDBIAS bits 14-15.
    pub fn sample_rate(&self) -> u32 {
        32768 << ((self.soundbias >> 14) & 3)
    }

    fn cycles_per_sample(&self) -> u32 {
        512 >> ((self.soundbias >> 14) & 3)
    }

    /// Advance audio by `cycles` system clocks, generating samples.
    pub fn step(&mut self, cycles: u32) {
        // Frame sequencer at 512 Hz => every 32768 cycles.
        self.frame_seq_timer -= cycles as i32;
        while self.frame_seq_timer <= 0 {
            self.frame_seq_timer += 32768;
            self.tick_frame_sequencer();
        }

        // Tick channel timers.
        self.tick_square_timer_ch1(cycles);
        self.tick_square_timer_ch2(cycles);
        self.tick_wave_timer(cycles);
        self.tick_noise_timer(cycles);

        // Output sampling (rate follows SOUNDBIAS).
        let cps = self.cycles_per_sample() as i32;
        self.sample_timer -= cycles as i32;
        while self.sample_timer <= 0 {
            self.sample_timer += cps;
            self.generate_sample();
        }
    }

    fn tick_frame_sequencer(&mut self) {
        let step = self.frame_seq;
        self.frame_seq = (self.frame_seq + 1) & 7;
        // Length at steps 0,2,4,6.
        if step & 1 == 0 {
            self.tick_length();
        }
        // Envelope at step 7.
        if step == 7 {
            self.tick_envelope();
        }
        // Sweep at steps 2,6.
        if step == 2 || step == 6 {
            self.tick_sweep();
        }
    }

    fn tick_length(&mut self) {
        if self.ch1.length_enable && self.ch1.length_counter > 0 {
            self.ch1.length_counter -= 1;
            if self.ch1.length_counter == 0 { self.ch1.enabled = false; }
        }
        if self.ch2.length_enable && self.ch2.length_counter > 0 {
            self.ch2.length_counter -= 1;
            if self.ch2.length_counter == 0 { self.ch2.enabled = false; }
        }
        if self.wave.length_enable && self.wave.length_counter > 0 {
            self.wave.length_counter -= 1;
            if self.wave.length_counter == 0 { self.wave.enabled = false; }
        }
        if self.noise.length_enable && self.noise.length_counter > 0 {
            self.noise.length_counter -= 1;
            if self.noise.length_counter == 0 { self.noise.enabled = false; }
        }
    }

    fn tick_envelope(&mut self) {
        for ch in [0, 1] {
            let c = if ch == 0 { &mut self.ch1 } else { &mut self.ch2 };
            if c.env_period != 0 {
                if c.env_timer > 0 { c.env_timer -= 1; }
                if c.env_timer == 0 {
                    c.env_timer = c.env_period;
                    if c.env_dir && c.env_vol < 15 { c.env_vol += 1; }
                    else if !c.env_dir && c.env_vol > 0 { c.env_vol -= 1; }
                }
            }
        }
        let n = &mut self.noise;
        if n.env_period != 0 {
            if n.env_timer > 0 { n.env_timer -= 1; }
            if n.env_timer == 0 {
                n.env_timer = n.env_period;
                if n.env_dir && n.env_vol < 15 { n.env_vol += 1; }
                else if !n.env_dir && n.env_vol > 0 { n.env_vol -= 1; }
            }
        }
    }

    fn tick_sweep(&mut self) {
        let c = &mut self.ch1;
        if !c.sweep_enable || c.sweep_period == 0 { return; }
        if c.sweep_timer > 0 { c.sweep_timer -= 1; }
        if c.sweep_timer == 0 {
            c.sweep_timer = c.sweep_period;
            let delta = c.sweep_shadow >> c.sweep_shift;
            let new = if c.sweep_dir {
                c.sweep_shadow.wrapping_sub(delta)
            } else {
                c.sweep_shadow.wrapping_add(delta)
            };
            if new > 2047 {
                c.enabled = false;
            } else if c.sweep_shift > 0 {
                c.sweep_shadow = new;
                c.freq = new;
            }
        }
    }

    fn tick_square_timer_ch1(&mut self, cycles: u32) {
        let c = &mut self.ch1;
        if !c.enabled { return; }
        c.timer -= cycles as i32;
        while c.timer <= 0 {
            c.timer += ((2048 - c.freq as i32) * 16).max(1);
            c.phase = (c.phase + 1) & 7;
        }
    }
    fn tick_square_timer_ch2(&mut self, cycles: u32) {
        let c = &mut self.ch2;
        if !c.enabled { return; }
        c.timer -= cycles as i32;
        while c.timer <= 0 {
            c.timer += ((2048 - c.freq as i32) * 16).max(1);
            c.phase = (c.phase + 1) & 7;
        }
    }
    fn tick_wave_timer(&mut self, cycles: u32) {
        let w = &mut self.wave;
        if !w.enabled || !w.dac_on { return; }
        w.timer -= cycles as i32;
        while w.timer <= 0 {
            w.timer += ((2048 - w.freq as i32) * 8).max(1);
            w.pos = (w.pos + 1) % if w.bank_mode { 64 } else { 32 };
            let idx = if w.bank_mode { w.pos } else { w.bank * 32 + w.pos };
            let byte = w.ram[(idx / 2) & 31];
            w.sample = if idx & 1 == 0 { byte >> 4 } else { byte & 0xF };
        }
    }
    fn tick_noise_timer(&mut self, cycles: u32) {
        let n = &mut self.noise;
        if !n.enabled { return; }
        let div = if n.divisor == 0 { 8 } else { (n.divisor as i32) * 16 };
        let period = (div << n.shift).max(1);
        n.timer -= cycles as i32;
        while n.timer <= 0 {
            n.timer += period;
            let bit = (n.lfsr ^ (n.lfsr >> 1)) & 1;
            n.lfsr >>= 1;
            n.lfsr |= bit << 14;
            if n.width7 {
                n.lfsr &= !(1 << 6);
                n.lfsr |= bit << 6;
            }
            n.sample = (!n.lfsr & 1) as u8;
        }
    }

    fn generate_sample(&mut self) {
        // PSG outputs (0..15 each), summed.
        let ch1 = if self.ch1.enabled {
            DUTY[self.ch1.duty as usize][self.ch1.phase as usize] as i32 * self.ch1.env_vol as i32
        } else { 0 };
        let ch2 = if self.ch2.enabled {
            DUTY[self.ch2.duty as usize][self.ch2.phase as usize] as i32 * self.ch2.env_vol as i32
        } else { 0 };
        let wave = if self.wave.enabled && self.wave.dac_on {
            let vol_shift = match self.wave.volume { 0 => 4, 1 => 0, 2 => 1, 3 => 2, _ => 4 };
            let s = if self.wave.force_vol { (self.wave.sample as i32 * 3) / 4 } else { self.wave.sample as i32 >> vol_shift };
            s
        } else { 0 };
        let noise = if self.noise.enabled {
            self.noise.sample as i32 * self.noise.env_vol as i32
        } else { 0 };

        // PSG mixing: channel enable per L/R from soundcnt_l.
        let cl = self.soundcnt_l;
        let psg_vol_r = (cl & 0x7) as i32;
        let psg_vol_l = ((cl >> 4) & 0x7) as i32;
        let mut psg_l = 0i32;
        let mut psg_r = 0i32;
        let chans = [ch1, ch2, wave, noise];
        for (i, &c) in chans.iter().enumerate() {
            if cl & (1 << (8 + i)) != 0 { psg_r += c; }   // right enable bits 8-11
            if cl & (1 << (12 + i)) != 0 { psg_l += c; }  // left enable bits 12-15
        }
        // Apply master volume (0-7) +1.
        psg_l = psg_l * (psg_vol_l + 1);
        psg_r = psg_r * (psg_vol_r + 1);

        // PSG sound volume from soundcnt_h bits 0-1: 0=25%,1=50%,2=100%.
        let psg_shift = match self.soundcnt_h & 0x3 { 0 => 3, 1 => 2, _ => 1 };
        psg_l >>= psg_shift;
        psg_r >>= psg_shift;

        // Direct Sound A/B.
        let h = self.soundcnt_h;
        let a_vol = if h & 0x4 != 0 { 1 } else { 0 }; // 0=50%,1=100%
        let b_vol = if h & 0x8 != 0 { 1 } else { 0 };
        let a = self.fifo_a.current as i32;
        let b = self.fifo_b.current as i32;
        let a_scaled = if a_vol == 1 { a } else { a >> 1 };
        let b_scaled = if b_vol == 1 { b } else { b >> 1 };

        let mut l = psg_l * 2;
        let mut r = psg_r * 2;
        if h & 0x200 != 0 { l += a_scaled * 4; }  // A left
        if h & 0x100 != 0 { r += a_scaled * 4; }  // A right
        if h & 0x2000 != 0 { l += b_scaled * 4; } // B left
        if h & 0x1000 != 0 { r += b_scaled * 4; } // B right

        // Scale to i16. DS at 100% spans ~±512 (sample*4); map that to i16.
        let scale = 32;
        let lo = (l * scale).clamp(-32768, 32767) as i16;
        let ro = (r * scale).clamp(-32768, 32767) as i16;
        self.buffer.push(lo);
        self.buffer.push(ro);
    }

    pub fn drain(&mut self) -> &[i16] {
        &self.buffer
    }
}
