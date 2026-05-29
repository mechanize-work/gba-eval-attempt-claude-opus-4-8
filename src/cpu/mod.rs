//! ARM7TDMI CPU core.

pub mod arm;
pub mod thumb;

/// Memory access timing class.
#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Access {
    NonSeq,
    Seq,
}

/// Interface the CPU uses to touch the rest of the machine. Implemented by the
/// system bus. All accesses advance the global cycle counter / scheduler.
pub trait Bus {
    fn read8(&mut self, addr: u32, access: Access) -> u8;
    fn read16(&mut self, addr: u32, access: Access) -> u16;
    fn read32(&mut self, addr: u32, access: Access) -> u32;
    fn write8(&mut self, addr: u32, val: u8, access: Access);
    fn write16(&mut self, addr: u32, val: u16, access: Access);
    fn write32(&mut self, addr: u32, val: u32, access: Access);
    /// Instruction (code) fetch. May be served by the game-pak prefetch buffer;
    /// default implementation just performs a normal read.
    fn fetch16(&mut self, addr: u32, access: Access) -> u16 {
        self.read16(addr, access)
    }
    fn fetch32(&mut self, addr: u32, access: Access) -> u32 {
        self.read32(addr, access)
    }
    /// Internal cycles (no bus access).
    fn idle(&mut self, cycles: u32);
    /// True if an enabled+requested IRQ is pending (IE & IF & IME).
    fn irq_pending(&self) -> bool;
}

// CPU operating modes (CPSR[4:0]).
pub const MODE_USER: u32 = 0x10;
pub const MODE_FIQ: u32 = 0x11;
pub const MODE_IRQ: u32 = 0x12;
pub const MODE_SVC: u32 = 0x13;
pub const MODE_ABT: u32 = 0x17;
pub const MODE_UND: u32 = 0x1B;
pub const MODE_SYS: u32 = 0x1F;

// CPSR flag bit positions.
pub const FLAG_N: u32 = 1 << 31;
pub const FLAG_Z: u32 = 1 << 30;
pub const FLAG_C: u32 = 1 << 29;
pub const FLAG_V: u32 = 1 << 28;
pub const FLAG_I: u32 = 1 << 7;
pub const FLAG_F: u32 = 1 << 6;
pub const FLAG_T: u32 = 1 << 5;

#[inline]
fn mode_bank(mode: u32) -> usize {
    match mode {
        MODE_FIQ => 1,
        MODE_IRQ => 2,
        MODE_SVC => 3,
        MODE_ABT => 4,
        MODE_UND => 5,
        _ => 0, // user/sys
    }
}

#[derive(Clone)]
pub struct Cpu {
    /// Active registers r0..r15.
    pub r: [u32; 16],
    pub cpsr: u32,

    /// r8..r12 banks: [0]=normal, [1]=fiq.
    bank_8_12: [[u32; 5]; 2],
    /// r13,r14 banks indexed by mode_bank(): 0=usr/sys,1=fiq,2=irq,3=svc,4=abt,5=und.
    bank_13_14: [[u32; 2]; 6],
    /// SPSR indexed by mode_bank() (index 0 unused).
    spsr: [u32; 6],

    /// Pipeline: prefetched opcodes. [0] = instruction to execute, [1] = next.
    pub pipe: [u32; 2],
    /// Set true by flush_pipeline so step() knows not to auto-advance r15.
    pub branched: bool,

    pub halted: bool,
}

impl Cpu {
    pub fn new() -> Self {
        let mut c = Cpu {
            r: [0; 16],
            cpsr: MODE_SVC | FLAG_I | FLAG_F,
            bank_8_12: [[0; 5]; 2],
            bank_13_14: [[0; 2]; 6],
            spsr: [0; 6],
            pipe: [0; 2],
            branched: false,
            halted: false,
        };
        c.reset();
        c
    }

    pub fn reset(&mut self) {
        self.r = [0; 16];
        self.cpsr = MODE_SVC | FLAG_I | FLAG_F;
        self.bank_8_12 = [[0; 5]; 2];
        self.bank_13_14 = [[0; 2]; 6];
        self.spsr = [0; 6];
        self.pipe = [0; 2];
        self.branched = false;
        self.halted = false;
    }

    #[inline]
    pub fn thumb(&self) -> bool {
        self.cpsr & FLAG_T != 0
    }

    #[inline]
    pub fn mode(&self) -> u32 {
        self.cpsr & 0x1F
    }

    #[inline]
    pub fn flag(&self, f: u32) -> bool {
        self.cpsr & f != 0
    }

    #[inline]
    pub fn set_flag(&mut self, f: u32, v: bool) {
        if v {
            self.cpsr |= f;
        } else {
            self.cpsr &= !f;
        }
    }

    pub fn get_spsr(&self) -> u32 {
        let b = mode_bank(self.mode());
        if b == 0 {
            self.cpsr
        } else {
            self.spsr[b]
        }
    }

    pub fn set_spsr(&mut self, val: u32) {
        let b = mode_bank(self.mode());
        if b != 0 {
            self.spsr[b] = val;
        }
    }

    pub fn has_spsr(&self) -> bool {
        mode_bank(self.mode()) != 0
    }

    /// Save active r8..r14 into the banks for `old_mode`, load banks for `new_mode`.
    fn switch_mode_banks(&mut self, old_mode: u32, new_mode: u32) {
        let old_b = mode_bank(old_mode);
        let new_b = mode_bank(new_mode);
        if old_b == new_b {
            return;
        }
        // r8..r12: only differ between fiq (bank 1) and everything else (bank 0).
        let old_fiq = (old_b == 1) as usize;
        let new_fiq = (new_b == 1) as usize;
        if old_fiq != new_fiq {
            for i in 0..5 {
                self.bank_8_12[old_fiq][i] = self.r[8 + i];
            }
            for i in 0..5 {
                self.r[8 + i] = self.bank_8_12[new_fiq][i];
            }
        }
        // r13,r14.
        self.bank_13_14[old_b][0] = self.r[13];
        self.bank_13_14[old_b][1] = self.r[14];
        self.r[13] = self.bank_13_14[new_b][0];
        self.r[14] = self.bank_13_14[new_b][1];
    }

    /// Set CPSR, handling mode bank switches. Preserves nothing else.
    pub fn set_cpsr(&mut self, val: u32) {
        let old_mode = self.mode();
        let new_mode = val & 0x1F;
        if old_mode != new_mode {
            self.switch_mode_banks(old_mode, new_mode);
        }
        self.cpsr = val;
    }

    /// Refill the pipeline after a branch / PC write. r[15] should hold the
    /// target address; afterwards r[15] points 2 instructions ahead (= PC+8/+4
    /// as instructions expect to read during execution).
    #[inline]
    pub fn flush_pipeline<B: Bus>(&mut self, bus: &mut B) {
        if self.thumb() {
            let pc = self.r[15] & !1;
            self.pipe[0] = bus.fetch16(pc, Access::NonSeq) as u32;
            self.pipe[1] = bus.fetch16(pc.wrapping_add(2), Access::Seq) as u32;
            self.r[15] = pc.wrapping_add(4);
        } else {
            let pc = self.r[15] & !3;
            self.pipe[0] = bus.fetch32(pc, Access::NonSeq);
            self.pipe[1] = bus.fetch32(pc.wrapping_add(4), Access::Seq);
            self.r[15] = pc.wrapping_add(8);
        }
        self.branched = true;
    }

    /// Execute one instruction (pipeline must be primed). During execution
    /// r[15] reads as instruction_addr + 2*size (PC+8 ARM / PC+4 Thumb).
    pub fn step<B: Bus>(&mut self, bus: &mut B) {
        let opcode = self.pipe[0];
        self.pipe[0] = self.pipe[1];
        self.branched = false;

        if self.thumb() {
            // Thumb: deferred prefetch (matches oracle's 2-fetch branch timing).
            thumb::execute(self, bus, opcode as u16);
            if !self.branched {
                let pc = self.r[15] & !1;
                self.pipe[1] = bus.fetch16(pc, Access::Seq) as u32;
                self.r[15] = pc.wrapping_add(2);
            }
        } else {
            // ARM: deferred prefetch (experiment with +1 waitstate model).
            arm::execute(self, bus, opcode);
            if !self.branched {
                let pc = self.r[15] & !3;
                self.pipe[1] = bus.fetch32(pc, Access::Seq);
                self.r[15] = pc.wrapping_add(4);
            }
        }
    }

    /// Enter the IRQ exception. Call only when IRQs are unmasked and pending.
    pub fn enter_irq<B: Bus>(&mut self, bus: &mut B) {
        let cpsr = self.cpsr;
        // Return address: address of the instruction that *would* execute next,
        // plus 4. r[15] currently points two instructions ahead of the one that
        // would have executed (pipe[0]). pipe[0] origin = r15 - (2*isize).
        let lr = if self.thumb() {
            self.r[15] // thumb: r15 = pipe0_addr + 4; need pipe0_addr + 4 => r15
        } else {
            self.r[15].wrapping_sub(4)
        };
        self.switch_mode_banks(self.mode(), MODE_IRQ);
        self.cpsr = (self.cpsr & !0x1F) | MODE_IRQ;
        self.spsr[mode_bank(MODE_IRQ)] = cpsr;
        self.set_flag(FLAG_T, false);
        self.set_flag(FLAG_I, true);
        self.r[14] = lr;
        self.r[15] = 0x18;
        self.flush_pipeline(bus);
        self.halted = false;
    }

    /// Software interrupt (SWI).
    pub fn enter_swi<B: Bus>(&mut self, bus: &mut B) {
        let cpsr = self.cpsr;
        // LR = address of instruction after the SWI.
        let lr = if self.thumb() {
            self.r[15].wrapping_sub(2)
        } else {
            self.r[15].wrapping_sub(4)
        };
        self.switch_mode_banks(self.mode(), MODE_SVC);
        self.cpsr = (self.cpsr & !0x1F) | MODE_SVC;
        self.spsr[mode_bank(MODE_SVC)] = cpsr;
        self.set_flag(FLAG_T, false);
        self.set_flag(FLAG_I, true);
        self.r[14] = lr;
        self.r[15] = 0x08;
        self.flush_pipeline(bus);
    }

    /// Undefined instruction exception.
    pub fn enter_undef<B: Bus>(&mut self, bus: &mut B) {
        let cpsr = self.cpsr;
        let lr = if self.thumb() {
            self.r[15].wrapping_sub(2)
        } else {
            self.r[15].wrapping_sub(4)
        };
        self.switch_mode_banks(self.mode(), MODE_UND);
        self.cpsr = (self.cpsr & !0x1F) | MODE_UND;
        self.spsr[mode_bank(MODE_UND)] = cpsr;
        self.set_flag(FLAG_T, false);
        self.set_flag(FLAG_I, true);
        self.r[14] = lr;
        self.r[15] = 0x04;
        self.flush_pipeline(bus);
    }
}
