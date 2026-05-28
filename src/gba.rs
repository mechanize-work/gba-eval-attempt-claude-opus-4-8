//! Top-level emulator: CPU + system bus, frame loop, DMA, IRQ.

use crate::bus::SysBus;
use crate::cpu::{Access, Bus, Cpu};
use crate::ppu;

pub struct Gba {
    pub cpu: Cpu,
    pub bus: SysBus,
    audio_drained: bool,
    rom_loaded: bool,
    pub insn_count: u64,
}

const BIOS_STUB: &[u8] = include_bytes!("../spec/gba_bios_stub.bin");

impl Gba {
    pub fn new() -> Self {
        let mut bus = SysBus::new();
        bus.load_bios(BIOS_STUB);
        Gba {
            cpu: Cpu::new(),
            bus,
            audio_drained: false,
            rom_loaded: false,
            insn_count: 0,
        }
    }

    pub fn load_rom(&mut self, rom: &[u8]) {
        self.bus.load_rom(rom);
        self.rom_loaded = true;
        self.reset();
    }

    pub fn reset(&mut self) {
        self.cpu.reset();
        self.bus.reset();
        // Begin executing the BIOS at 0x0.
        self.cpu.r[15] = 0;
        self.cpu.flush_pipeline(&mut self.bus);
    }

    pub fn set_keys(&mut self, k: u32) {
        self.bus.keyinput = (!k as u16) & 0x03FF;
    }

    pub fn run_frame(&mut self) {
        if self.audio_drained {
            self.bus.apu.buffer.clear();
            self.audio_drained = false;
        }
        // Safety net: if the host never drains audio, cap memory by dropping the
        // oldest samples once the buffer grows very large (~16 MB).
        if self.bus.apu.buffer.len() > 8_000_000 {
            let keep = 4_000_000;
            let start = self.bus.apu.buffer.len() - keep;
            self.bus.apu.buffer.drain(0..start);
        }
        self.bus.frame_complete = false;
        let mut guard: u64 = 0;
        let max_cycles: u64 = ppu::CYCLES_PER_LINE as u64 * ppu::TOTAL_LINES as u64 * 4;
        let start = self.bus.sched.now;

        while !self.bus.frame_complete {
            self.service_dma();

            if self.bus.frame_complete {
                break;
            }

            if self.bus.halted {
                self.run_halted();
                continue;
            }

            // Take IRQ if pending and enabled.
            if !self.cpu.flag(crate::cpu::FLAG_I) && self.bus.irq_active() {
                self.cpu.enter_irq(&mut self.bus);
            }

            self.cpu.step(&mut self.bus);
            self.insn_count += 1;

            // Safety guard against runaway loops.
            guard += 1;
            if guard > 20_000_000 || self.bus.sched.now.wrapping_sub(start) > max_cycles {
                break;
            }
        }
    }

    /// Advance time while the CPU is halted until an interrupt is requested.
    fn run_halted(&mut self) {
        // Tick in small steps so PPU/timer events post interrupts at the right time.
        while self.bus.halted && !self.bus.frame_complete {
            if (self.bus.ie & self.bus.if_) != 0 {
                self.bus.halted = false;
                break;
            }
            // A pending DMA (incl. sound FIFO refill) must be serviced by the
            // main loop, so stop halting and let it run.
            if self.bus.dma_pending != 0
                || self.bus.fifo_a_request
                || self.bus.fifo_b_request
            {
                break;
            }
            self.bus.idle(8);
        }
    }

    /// Run all pending DMA channels (highest priority first).
    fn service_dma(&mut self) {
        // Handle sound FIFO requests -> mark relevant channels pending.
        if self.bus.fifo_a_request {
            self.bus.fifo_a_request = false;
            self.queue_fifo_dma(0xA0);
        }
        if self.bus.fifo_b_request {
            self.bus.fifo_b_request = false;
            self.queue_fifo_dma(0xA4);
        }

        while self.bus.dma_pending != 0 {
            // Find highest priority (lowest index) pending channel.
            let ch = self.bus.dma_pending.trailing_zeros() as usize;
            self.bus.dma_pending &= !(1 << ch);
            self.run_dma(ch);
        }
    }

    fn queue_fifo_dma(&mut self, fifo_low: u32) {
        let fifo_addr = 0x0400_0000 | fifo_low;
        for ch in 1..=2usize {
            let c = &self.bus.dma.ch[ch];
            if c.enabled() && c.timing() == 3 && (c.dst & 0xFFFF) == (fifo_addr & 0xFFFF) {
                self.bus.dma_pending |= 1 << ch;
            }
        }
    }

    fn run_dma(&mut self, ch: usize) {
        let c = self.bus.dma.ch[ch];
        if !c.enabled() {
            return;
        }
        let timing = c.timing();
        let is_fifo = timing == 3 && (ch == 1 || ch == 2);

        let word32 = c.word_size() || is_fifo;
        let unit = if word32 { 4u32 } else { 2u32 };

        let src_adj = c.src_adjust();
        let dst_adj = c.dst_adjust();

        let count = if is_fifo { 4 } else { c.cur_count };

        // EEPROM size auto-detect: a DMA to the EEPROM region reveals the address
        // width by its transfer length (read cmd = 2+addr+1; write = 2+addr+64+1).
        if self.bus.save.is_eeprom() && (c.cur_dst >> 24) & 0xF == 0xD {
            self.bus.eeprom_addr_bits = match count {
                9 | 73 => 6,
                17 | 81 => 14,
                _ => self.bus.eeprom_addr_bits,
            };
        }

        let mut src = self.bus.dma.ch[ch].cur_src;
        let mut dst = self.bus.dma.ch[ch].cur_dst;

        let mut access = Access::NonSeq;
        for _ in 0..count {
            if word32 {
                let v = self.bus.read32(src & !3, access);
                self.bus.write32(dst & !3, v, access);
            } else {
                let v = self.bus.read16(src & !1, access);
                self.bus.write16(dst & !1, v, access);
            }
            access = Access::Seq;
            // Source adjust.
            match src_adj {
                0 => src = src.wrapping_add(unit),
                1 => src = src.wrapping_sub(unit),
                _ => {}
            }
            // Dest adjust (FIFO: fixed).
            if !is_fifo {
                match dst_adj {
                    0 | 3 => dst = dst.wrapping_add(unit),
                    1 => dst = dst.wrapping_sub(unit),
                    _ => {}
                }
            }
        }

        // Update latched pointers.
        self.bus.dma.ch[ch].cur_src = src;
        if !is_fifo {
            self.bus.dma.ch[ch].cur_dst = dst;
        }

        // IRQ on completion.
        if self.bus.dma.ch[ch].irq() {
            self.bus.if_ |= crate::bus::IRQ_DMA0 << ch;
        }

        // Repeat handling.
        let repeat = self.bus.dma.ch[ch].repeat();
        if repeat && timing != 0 {
            // Reload count; for dst_adj==3 (increment/reload) reload dst too.
            if !is_fifo {
                let orig = self.bus.dma.ch[ch].count;
                self.bus.dma.ch[ch].cur_count = if orig == 0 {
                    if ch == 3 { 0x10000 } else { 0x4000 }
                } else {
                    orig
                };
                if dst_adj == 3 {
                    self.bus.dma.ch[ch].cur_dst = self.bus.dma.ch[ch].dst;
                }
            }
            // Stays enabled, waits for next trigger.
        } else {
            // Clear enable bit.
            self.bus.dma.ch[ch].control &= !0x8000;
            self.bus.dma.ch[ch].active = false;
        }
    }

    pub fn framebuffer(&self) -> &[u32] {
        &self.bus.ppu.frame
    }

    pub fn audio_buffer(&self) -> *const i16 {
        self.bus.apu.buffer.as_ptr()
    }

    pub fn audio_samples(&mut self) -> i32 {
        let n = (self.bus.apu.buffer.len() / 2) as i32;
        self.audio_drained = true;
        n
    }

    pub fn audio_rate(&self) -> i32 {
        self.bus.apu.sample_rate() as i32
    }
}
