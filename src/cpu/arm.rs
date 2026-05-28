//! ARM instruction set execution.
use super::*;

#[inline]
pub fn cond_passed(cpu: &Cpu, cond: u32) -> bool {
    let n = cpu.flag(FLAG_N);
    let z = cpu.flag(FLAG_Z);
    let c = cpu.flag(FLAG_C);
    let v = cpu.flag(FLAG_V);
    match cond {
        0x0 => z,                       // EQ
        0x1 => !z,                      // NE
        0x2 => c,                       // CS
        0x3 => !c,                      // CC
        0x4 => n,                       // MI
        0x5 => !n,                      // PL
        0x6 => v,                       // VS
        0x7 => !v,                      // VC
        0x8 => c && !z,                 // HI
        0x9 => !c || z,                 // LS
        0xA => n == v,                  // GE
        0xB => n != v,                  // LT
        0xC => !z && (n == v),          // GT
        0xD => z || (n != v),           // LE
        0xE => true,                    // AL
        _ => true,                      // NV (treated as AL on ARMv4 it's unpredictable; never used)
    }
}

pub fn execute<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let cond = op >> 28;
    if cond != 0xE && !cond_passed(cpu, cond) {
        return;
    }

    // Branch and Exchange: 0001 0010 1111 1111 1111 0001 nnnn
    if (op & 0x0FFF_FFF0) == 0x012F_FF10 {
        let rn = (op & 0xF) as usize;
        let addr = cpu.r[rn];
        cpu.set_flag(FLAG_T, addr & 1 != 0);
        cpu.r[15] = addr;
        cpu.flush_pipeline(bus);
        return;
    }

    let bits2725 = (op >> 25) & 0x7;
    match bits2725 {
        0b101 => branch(cpu, bus, op),
        0b100 => block_transfer(cpu, bus, op),
        0b111 => {
            if (op >> 24) & 1 == 1 {
                // SWI
                cpu.enter_swi(bus);
            } else {
                cpu.enter_undef(bus); // coprocessor — undefined on GBA
            }
        }
        0b110 => cpu.enter_undef(bus), // coprocessor data transfer
        0b011 => {
            // Could be single data transfer or undefined (bit4=1 of this class)
            if (op >> 4) & 1 == 1 {
                cpu.enter_undef(bus);
            } else {
                single_data_transfer(cpu, bus, op);
            }
        }
        0b010 => single_data_transfer(cpu, bus, op),
        0b000 | 0b001 => data_proc_class(cpu, bus, op),
        _ => unreachable!(),
    }
}

fn data_proc_class<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let immediate = (op >> 25) & 1 == 1;
    if !immediate {
        // Check for multiply / swap / halfword which live in the 000 space.
        let bit7 = (op >> 7) & 1;
        let bit4 = (op >> 4) & 1;
        if bit4 == 1 && bit7 == 1 {
            // Multiply, multiply long, swap, or halfword transfer.
            let bits74 = (op >> 4) & 0xF;
            if bits74 == 0b1001 {
                // Multiply class or swap.
                let bits2723 = (op >> 23) & 0x1F;
                if bits2723 == 0b00010 {
                    swap(cpu, bus, op);
                    return;
                } else if (op >> 24) & 0xF == 0 {
                    // bits 27-24 == 0000 => MUL/MLA; 0000 1 => MULL/MLAL
                    if (op >> 23) & 1 == 0 {
                        multiply(cpu, op);
                    } else {
                        multiply_long(cpu, op);
                    }
                    return;
                } else {
                    multiply_long(cpu, op);
                    return;
                }
            } else {
                // Halfword / signed data transfer (bits74 = 1011/1101/1111).
                halfword_transfer(cpu, bus, op);
                return;
            }
        }
    }
    // PSR transfer: TST/TEQ/CMP/CMN (opcode 1000..1011) with S=0.
    let opcode = (op >> 21) & 0xF;
    let s = (op >> 20) & 1;
    if s == 0 && (0b1000..=0b1011).contains(&opcode) {
        psr_transfer(cpu, op);
        return;
    }
    data_processing(cpu, bus, op);
}

// --- Barrel shifter ---------------------------------------------------------

/// Compute shifted operand and carry out for register-shift data processing.
/// `imm` selects immediate (true) vs register operand. Returns (value, carry).
fn shift_operand<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) -> (u32, bool) {
    let immediate = (op >> 25) & 1 == 1;
    let old_c = cpu.flag(FLAG_C);
    if immediate {
        let imm = op & 0xFF;
        let rot = ((op >> 8) & 0xF) * 2;
        if rot == 0 {
            (imm, old_c)
        } else {
            let val = imm.rotate_right(rot);
            (val, val & 0x8000_0000 != 0)
        }
    } else {
        let rm = (op & 0xF) as usize;
        let shift_type = (op >> 5) & 0x3;
        let reg_shift = (op >> 4) & 1 == 1;
        let amount;
        let mut rm_val = cpu.r[rm];
        if reg_shift {
            // r15 reads as +12 when used as Rm with register shift.
            if rm == 15 {
                rm_val = rm_val.wrapping_add(4);
            }
            let rs = (op >> 8) & 0xF;
            // shifting by register costs 1 internal cycle
            bus.idle(1);
            // also if rm is r15 and Rn is r15 ... handled by rm_val above.
            amount = cpu.r[rs as usize] & 0xFF;
            apply_shift_reg(shift_type, rm_val, amount, old_c)
        } else {
            amount = (op >> 7) & 0x1F;
            apply_shift_imm(shift_type, rm_val, amount, old_c)
        }
    }
}

#[inline]
pub fn apply_shift_imm(shift_type: u32, val: u32, amount: u32, carry_in: bool) -> (u32, bool) {
    match shift_type {
        0 => {
            // LSL
            if amount == 0 {
                (val, carry_in)
            } else {
                let c = (val >> (32 - amount)) & 1 != 0;
                (val << amount, c)
            }
        }
        1 => {
            // LSR; amount 0 means 32
            if amount == 0 {
                (0, val & 0x8000_0000 != 0)
            } else {
                let c = (val >> (amount - 1)) & 1 != 0;
                (val >> amount, c)
            }
        }
        2 => {
            // ASR; amount 0 means 32
            if amount == 0 {
                let c = val & 0x8000_0000 != 0;
                ((val as i32 >> 31) as u32, c)
            } else {
                let c = ((val as i32) >> (amount - 1)) & 1 != 0;
                (((val as i32) >> amount) as u32, c)
            }
        }
        3 => {
            // ROR; amount 0 means RRX
            if amount == 0 {
                let c = val & 1 != 0;
                let result = (val >> 1) | ((carry_in as u32) << 31);
                (result, c)
            } else {
                let c = (val >> (amount - 1)) & 1 != 0;
                (val.rotate_right(amount), c)
            }
        }
        _ => unreachable!(),
    }
}

#[inline]
pub fn apply_shift_reg(shift_type: u32, val: u32, amount: u32, carry_in: bool) -> (u32, bool) {
    if amount == 0 {
        return (val, carry_in);
    }
    match shift_type {
        0 => {
            // LSL
            if amount < 32 {
                let c = (val >> (32 - amount)) & 1 != 0;
                (val << amount, c)
            } else if amount == 32 {
                (0, val & 1 != 0)
            } else {
                (0, false)
            }
        }
        1 => {
            // LSR
            if amount < 32 {
                let c = (val >> (amount - 1)) & 1 != 0;
                (val >> amount, c)
            } else if amount == 32 {
                (0, val & 0x8000_0000 != 0)
            } else {
                (0, false)
            }
        }
        2 => {
            // ASR
            if amount < 32 {
                let c = ((val as i32) >> (amount - 1)) & 1 != 0;
                (((val as i32) >> amount) as u32, c)
            } else {
                let c = val & 0x8000_0000 != 0;
                ((val as i32 >> 31) as u32, c)
            }
        }
        3 => {
            // ROR
            let a = amount & 0x1F;
            if a == 0 {
                // amount is multiple of 32
                (val, val & 0x8000_0000 != 0)
            } else {
                let c = (val >> (a - 1)) & 1 != 0;
                (val.rotate_right(a), c)
            }
        }
        _ => unreachable!(),
    }
}

// --- Data processing --------------------------------------------------------

fn data_processing<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let opcode = (op >> 21) & 0xF;
    let s = (op >> 20) & 1 == 1;
    let rn = ((op >> 16) & 0xF) as usize;
    let rd = ((op >> 12) & 0xF) as usize;

    let reg_shift = (op >> 25) & 1 == 0 && (op >> 4) & 1 == 1;
    let (operand2, shifter_carry) = shift_operand(cpu, bus, op);

    // Rn value; r15 reads +12 if a register-specified shift was used.
    let mut rn_val = cpu.r[rn];
    if reg_shift && rn == 15 {
        rn_val = rn_val.wrapping_add(4);
    }

    let carry_in = cpu.flag(FLAG_C);
    let (result, write, set_cv): (u32, bool, Option<(bool, bool)>) = match opcode {
        0x0 => (rn_val & operand2, true, None),                       // AND
        0x1 => (rn_val ^ operand2, true, None),                       // EOR
        0x2 => {
            let (r, c, v) = sub_flags(rn_val, operand2);
            (r, true, Some((c, v)))
        } // SUB
        0x3 => {
            let (r, c, v) = sub_flags(operand2, rn_val);
            (r, true, Some((c, v)))
        } // RSB
        0x4 => {
            let (r, c, v) = add_flags(rn_val, operand2);
            (r, true, Some((c, v)))
        } // ADD
        0x5 => {
            let (r, c, v) = adc_flags(rn_val, operand2, carry_in);
            (r, true, Some((c, v)))
        } // ADC
        0x6 => {
            let (r, c, v) = sbc_flags(rn_val, operand2, carry_in);
            (r, true, Some((c, v)))
        } // SBC
        0x7 => {
            let (r, c, v) = sbc_flags(operand2, rn_val, carry_in);
            (r, true, Some((c, v)))
        } // RSC
        0x8 => (rn_val & operand2, false, None),                      // TST
        0x9 => (rn_val ^ operand2, false, None),                      // TEQ
        0xA => {
            let (r, c, v) = sub_flags(rn_val, operand2);
            (r, false, Some((c, v)))
        } // CMP
        0xB => {
            let (r, c, v) = add_flags(rn_val, operand2);
            (r, false, Some((c, v)))
        } // CMN
        0xC => (rn_val | operand2, true, None),                       // ORR
        0xD => (operand2, true, None),                                // MOV
        0xE => (rn_val & !operand2, true, None),                      // BIC
        0xF => (!operand2, true, None),                               // MVN
        _ => unreachable!(),
    };

    if s {
        if rd == 15 {
            // Restore CPSR from SPSR (return from exception).
            let spsr = cpu.get_spsr();
            cpu.set_cpsr(spsr);
        } else {
            cpu.set_flag(FLAG_Z, result == 0);
            cpu.set_flag(FLAG_N, result & 0x8000_0000 != 0);
            match set_cv {
                Some((c, v)) => {
                    cpu.set_flag(FLAG_C, c);
                    cpu.set_flag(FLAG_V, v);
                }
                None => {
                    cpu.set_flag(FLAG_C, shifter_carry);
                }
            }
        }
    }

    if write {
        if rd == 15 {
            cpu.r[15] = result;
            cpu.flush_pipeline(bus);
        } else {
            cpu.r[rd] = result;
        }
    }
}

#[inline]
pub fn add_flags(a: u32, b: u32) -> (u32, bool, bool) {
    let (r, c) = a.overflowing_add(b);
    let v = ((a ^ r) & (b ^ r)) & 0x8000_0000 != 0;
    (r, c, v)
}

#[inline]
pub fn sub_flags(a: u32, b: u32) -> (u32, bool, bool) {
    let r = a.wrapping_sub(b);
    let c = a >= b;
    let v = ((a ^ b) & (a ^ r)) & 0x8000_0000 != 0;
    (r, c, v)
}

#[inline]
pub fn adc_flags(a: u32, b: u32, carry: bool) -> (u32, bool, bool) {
    let c = carry as u64;
    let sum = a as u64 + b as u64 + c;
    let r = sum as u32;
    let carry_out = sum > 0xFFFF_FFFF;
    let v = ((a ^ r) & (b ^ r)) & 0x8000_0000 != 0;
    (r, carry_out, v)
}

#[inline]
pub fn sbc_flags(a: u32, b: u32, carry: bool) -> (u32, bool, bool) {
    let borrow = !carry as u64;
    let diff = (a as u64).wrapping_sub(b as u64).wrapping_sub(borrow);
    let r = diff as u32;
    let carry_out = (a as u64) >= (b as u64 + borrow);
    let v = ((a ^ b) & (a ^ r)) & 0x8000_0000 != 0;
    (r, carry_out, v)
}

// --- PSR transfer -----------------------------------------------------------

fn psr_transfer(cpu: &mut Cpu, op: u32) {
    let spsr = (op >> 22) & 1 == 1;
    if (op >> 21) & 1 == 0 {
        // MRS
        let rd = ((op >> 12) & 0xF) as usize;
        cpu.r[rd] = if spsr { cpu.get_spsr() } else { cpu.cpsr };
    } else {
        // MSR
        let immediate = (op >> 25) & 1 == 1;
        let value = if immediate {
            let imm = op & 0xFF;
            let rot = ((op >> 8) & 0xF) * 2;
            imm.rotate_right(rot)
        } else {
            cpu.r[(op & 0xF) as usize]
        };
        let mut mask: u32 = 0;
        if (op >> 19) & 1 == 1 {
            mask |= 0xFF00_0000; // flags
        }
        if (op >> 18) & 1 == 1 {
            mask |= 0x00FF_0000;
        }
        if (op >> 17) & 1 == 1 {
            mask |= 0x0000_FF00;
        }
        if (op >> 16) & 1 == 1 {
            mask |= 0x0000_00FF; // control
        }
        if spsr {
            if cpu.has_spsr() {
                let cur = cpu.get_spsr();
                cpu.set_spsr((cur & !mask) | (value & mask));
            }
        } else {
            // In user mode only flags can be changed.
            let mask = if cpu.mode() == MODE_USER {
                mask & 0xFF00_0000
            } else {
                mask
            };
            let new = (cpu.cpsr & !mask) | (value & mask);
            cpu.set_cpsr(new);
        }
    }
}

// --- Multiply ---------------------------------------------------------------

fn multiply(cpu: &mut Cpu, op: u32) {
    let rd = ((op >> 16) & 0xF) as usize;
    let rn = ((op >> 12) & 0xF) as usize;
    let rs = ((op >> 8) & 0xF) as usize;
    let rm = (op & 0xF) as usize;
    let accumulate = (op >> 21) & 1 == 1;
    let s = (op >> 20) & 1 == 1;
    let mut result = cpu.r[rm].wrapping_mul(cpu.r[rs]);
    if accumulate {
        result = result.wrapping_add(cpu.r[rn]);
    }
    cpu.r[rd] = result;
    if s {
        cpu.set_flag(FLAG_Z, result == 0);
        cpu.set_flag(FLAG_N, result & 0x8000_0000 != 0);
    }
}

fn multiply_long(cpu: &mut Cpu, op: u32) {
    let rdhi = ((op >> 16) & 0xF) as usize;
    let rdlo = ((op >> 12) & 0xF) as usize;
    let rs = ((op >> 8) & 0xF) as usize;
    let rm = (op & 0xF) as usize;
    let accumulate = (op >> 21) & 1 == 1;
    let s = (op >> 20) & 1 == 1;
    let signed = (op >> 22) & 1 == 1;

    let result: u64 = if signed {
        let a = cpu.r[rm] as i32 as i64;
        let b = cpu.r[rs] as i32 as i64;
        (a.wrapping_mul(b)) as u64
    } else {
        (cpu.r[rm] as u64).wrapping_mul(cpu.r[rs] as u64)
    };
    let mut result = result;
    if accumulate {
        let acc = ((cpu.r[rdhi] as u64) << 32) | (cpu.r[rdlo] as u64);
        result = result.wrapping_add(acc);
    }
    cpu.r[rdlo] = result as u32;
    cpu.r[rdhi] = (result >> 32) as u32;
    if s {
        cpu.set_flag(FLAG_Z, result == 0);
        cpu.set_flag(FLAG_N, result & 0x8000_0000_0000_0000 != 0);
    }
}

// --- Single data swap -------------------------------------------------------

fn swap<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let rn = ((op >> 16) & 0xF) as usize;
    let rd = ((op >> 12) & 0xF) as usize;
    let rm = (op & 0xF) as usize;
    let byte = (op >> 22) & 1 == 1;
    let addr = cpu.r[rn];
    if byte {
        let tmp = bus.read8(addr, Access::NonSeq);
        bus.write8(addr, cpu.r[rm] as u8, Access::NonSeq);
        cpu.r[rd] = tmp as u32;
    } else {
        let tmp = read32_rotate(bus, addr);
        bus.write32(addr, cpu.r[rm], Access::NonSeq);
        cpu.r[rd] = tmp;
    }
    bus.idle(1);
}

// --- Single data transfer (LDR/STR) ----------------------------------------

fn single_data_transfer<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let immediate = (op >> 25) & 1 == 0; // I=0 => immediate offset
    let pre = (op >> 24) & 1 == 1;
    let up = (op >> 23) & 1 == 1;
    let byte = (op >> 22) & 1 == 1;
    let writeback = (op >> 21) & 1 == 1;
    let load = (op >> 20) & 1 == 1;
    let rn = ((op >> 16) & 0xF) as usize;
    let rd = ((op >> 12) & 0xF) as usize;

    let offset = if immediate {
        op & 0xFFF
    } else {
        // Register offset with shift (immediate shift amount only).
        let rm = (op & 0xF) as usize;
        let shift_type = (op >> 5) & 0x3;
        let amount = (op >> 7) & 0x1F;
        let (v, _) = apply_shift_imm(shift_type, cpu.r[rm], amount, cpu.flag(FLAG_C));
        v
    };

    let base = cpu.r[rn];
    let offset_addr = if up {
        base.wrapping_add(offset)
    } else {
        base.wrapping_sub(offset)
    };
    let addr = if pre { offset_addr } else { base };

    if load {
        let value = if byte {
            bus.read8(addr, Access::NonSeq) as u32
        } else {
            read32_rotate(bus, addr)
        };
        bus.idle(1);
        // Writeback / post-index. Do base update before rd write per ARM (if rn!=rd).
        if (!pre || writeback) && rn != rd {
            cpu.r[rn] = offset_addr;
        }
        if rd == 15 {
            cpu.r[15] = value & !3;
            cpu.flush_pipeline(bus);
        } else {
            cpu.r[rd] = value;
        }
    } else {
        let mut value = cpu.r[rd];
        if rd == 15 {
            value = value.wrapping_add(4); // stored PC = instr+12
        }
        if byte {
            bus.write8(addr, value as u8, Access::NonSeq);
        } else {
            bus.write32(addr & !3, value, Access::NonSeq);
        }
        if !pre || writeback {
            cpu.r[rn] = offset_addr;
        }
    }
}

/// LDR with the ARM unaligned-address rotate behavior.
fn read32_rotate<B: Bus>(bus: &mut B, addr: u32) -> u32 {
    let aligned = addr & !3;
    let val = bus.read32(aligned, Access::NonSeq);
    let rot = (addr & 3) * 8;
    val.rotate_right(rot)
}

// --- Halfword / signed transfer --------------------------------------------

fn halfword_transfer<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let pre = (op >> 24) & 1 == 1;
    let up = (op >> 23) & 1 == 1;
    let imm_offset = (op >> 22) & 1 == 1;
    let writeback = (op >> 21) & 1 == 1;
    let load = (op >> 20) & 1 == 1;
    let rn = ((op >> 16) & 0xF) as usize;
    let rd = ((op >> 12) & 0xF) as usize;
    let sh = (op >> 5) & 0x3;

    let offset = if imm_offset {
        ((op >> 4) & 0xF0) | (op & 0xF)
    } else {
        cpu.r[(op & 0xF) as usize]
    };

    let base = cpu.r[rn];
    let offset_addr = if up {
        base.wrapping_add(offset)
    } else {
        base.wrapping_sub(offset)
    };
    let addr = if pre { offset_addr } else { base };

    if load {
        let value = match sh {
            0b01 => {
                // LDRH (unaligned rotates)
                let aligned = addr & !1;
                let v = bus.read16(aligned, Access::NonSeq) as u32;
                if addr & 1 != 0 {
                    v.rotate_right(8)
                } else {
                    v
                }
            }
            0b10 => {
                // LDRSB
                bus.read8(addr, Access::NonSeq) as i8 as i32 as u32
            }
            0b11 => {
                // LDRSH; if misaligned, behaves like LDRSB
                if addr & 1 != 0 {
                    bus.read8(addr, Access::NonSeq) as i8 as i32 as u32
                } else {
                    bus.read16(addr, Access::NonSeq) as i16 as i32 as u32
                }
            }
            _ => 0,
        };
        bus.idle(1);
        if (!pre || writeback) && rn != rd {
            cpu.r[rn] = offset_addr;
        }
        if rd == 15 {
            cpu.r[15] = value & !1;
            cpu.flush_pipeline(bus);
        } else {
            cpu.r[rd] = value;
        }
    } else {
        // STRH
        let mut value = cpu.r[rd];
        if rd == 15 {
            value = value.wrapping_add(4);
        }
        bus.write16(addr & !1, value as u16, Access::NonSeq);
        if !pre || writeback {
            cpu.r[rn] = offset_addr;
        }
    }
}

// --- Block data transfer (LDM/STM) -----------------------------------------

fn block_transfer<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let pre = (op >> 24) & 1 == 1;
    let up = (op >> 23) & 1 == 1;
    let s_bit = (op >> 22) & 1 == 1;
    let writeback = (op >> 21) & 1 == 1;
    let load = (op >> 20) & 1 == 1;
    let rn = ((op >> 16) & 0xF) as usize;
    let mut reg_list = op & 0xFFFF;
    let base = cpu.r[rn];

    let r15_in_list = reg_list & 0x8000 != 0;
    // Whether to use the user-mode register bank for the transfer.
    let use_user_bank = s_bit && !(load && r15_in_list);

    // Handle empty list (ARMv4 quirk): transfers r15 only, base +/- 0x40.
    let (num_regs, empty) = if reg_list == 0 {
        reg_list = 0x8000;
        (16u32, true)
    } else {
        (reg_list.count_ones(), false)
    };

    // Lowest address of the transfer block.
    let mut addr = if up {
        if pre { base.wrapping_add(4) } else { base }
    } else if pre {
        base.wrapping_sub(num_regs * 4)
    } else {
        base.wrapping_sub(num_regs * 4).wrapping_add(4)
    };

    let writeback_val = if up {
        base.wrapping_add(num_regs * 4)
    } else {
        base.wrapping_sub(num_regs * 4)
    };

    let saved_mode = cpu.mode();
    let swapped = use_user_bank && saved_mode != MODE_USER && saved_mode != MODE_SYS;
    if swapped {
        cpu.switch_mode_banks(saved_mode, MODE_USER);
    }

    let rn_in_list = (op & 0xFFFF) & (1 << rn) != 0;
    let rn_first = rn_in_list && ((op & 0xFFFF) & ((1u32 << rn) - 1)) == 0;

    let mut access = Access::NonSeq;

    if load {
        for i in 0..16 {
            if reg_list & (1 << i) == 0 {
                continue;
            }
            let v = bus.read32(addr & !3, access);
            access = Access::Seq;
            addr = addr.wrapping_add(4);
            if i == 15 {
                cpu.r[15] = v & !3;
                if s_bit {
                    let spsr = cpu.get_spsr();
                    cpu.set_cpsr(spsr);
                }
                cpu.flush_pipeline(bus);
            } else {
                cpu.r[i] = v;
            }
        }
        bus.idle(1);
        // Writeback only if rn wasn't loaded.
        if writeback && (!rn_in_list || empty) {
            cpu.r[rn] = writeback_val;
        }
    } else {
        let mut idx = 0;
        for i in 0..16 {
            if reg_list & (1 << i) == 0 {
                continue;
            }
            let mut v = cpu.r[i];
            if i == 15 {
                v = v.wrapping_add(4); // PC+12
            }
            if i == rn && writeback && !rn_first {
                v = writeback_val; // stored base is the written-back value
            }
            bus.write32(addr & !3, v, access);
            access = Access::Seq;
            addr = addr.wrapping_add(4);
            idx += 1;
            let _ = idx;
        }
        if writeback {
            cpu.r[rn] = writeback_val;
        }
    }

    if swapped {
        cpu.switch_mode_banks(MODE_USER, saved_mode);
    }
    let _ = empty;
}

// --- Branch -----------------------------------------------------------------

fn branch<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let link = (op >> 24) & 1 == 1;
    let offset = ((op & 0x00FF_FFFF) << 8) as i32 >> 6; // sign-extend, *4
    let pc = cpu.r[15]; // = instr_addr + 8
    if link {
        cpu.r[14] = pc.wrapping_sub(4); // address of next instruction
    }
    cpu.r[15] = pc.wrapping_add(offset as u32);
    cpu.flush_pipeline(bus);
}
