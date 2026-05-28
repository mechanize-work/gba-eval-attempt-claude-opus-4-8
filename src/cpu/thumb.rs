//! Thumb instruction set execution.
use super::arm::{add_flags, adc_flags, apply_shift_imm, apply_shift_reg, cond_passed, sbc_flags, sub_flags};
use super::*;

pub fn execute<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u16) {
    let op = op as u32;
    let hi = op >> 8;
    match hi {
        // Format 1: move shifted register (LSL/LSR/ASR).
        0x00..=0x17 => move_shifted(cpu, op),
        // Format 2: add/subtract.
        0x18..=0x1F => add_sub(cpu, op),
        0x20..=0x3F => mov_cmp_add_sub_imm(cpu, op),
        0x40..=0x43 => alu_ops(cpu, bus, op),
        0x44..=0x47 => hi_reg_bx(cpu, bus, op),
        0x48..=0x4F => pc_relative_load(cpu, bus, op),
        0x50..=0x5F => {
            if (op >> 9) & 1 == 1 {
                load_store_sign_ext(cpu, bus, op);
            } else {
                load_store_reg(cpu, bus, op);
            }
        }
        0x60..=0x7F => load_store_imm(cpu, bus, op),
        0x80..=0x8F => load_store_half(cpu, bus, op),
        0x90..=0x9F => sp_relative(cpu, bus, op),
        0xA0..=0xAF => load_address(cpu, op),
        0xB0 => add_sp_offset(cpu, op),
        0xB4..=0xB5 | 0xBC..=0xBD => push_pop(cpu, bus, op),
        0xC0..=0xCF => block_transfer(cpu, bus, op),
        0xD0..=0xDF => {
            let cond = (op >> 8) & 0xF;
            if cond == 0xF {
                cpu.enter_swi(bus);
            } else if cond == 0xE {
                cpu.enter_undef(bus);
            } else {
                cond_branch(cpu, bus, op, cond);
            }
        }
        0xE0..=0xE7 => uncond_branch(cpu, bus, op),
        0xF0..=0xFF => long_branch_link(cpu, bus, op),
        _ => cpu.enter_undef(bus),
    }
}

// Format 1
fn move_shifted(cpu: &mut Cpu, op: u32) {
    let shift_type = (op >> 11) & 0x3;
    let amount = (op >> 6) & 0x1F;
    let rs = ((op >> 3) & 0x7) as usize;
    let rd = (op & 0x7) as usize;
    let (result, carry) = apply_shift_imm(shift_type, cpu.r[rs], amount, cpu.flag(FLAG_C));
    cpu.r[rd] = result;
    cpu.set_flag(FLAG_C, carry);
    cpu.set_flag(FLAG_Z, result == 0);
    cpu.set_flag(FLAG_N, result & 0x8000_0000 != 0);
}

// Format 2
fn add_sub(cpu: &mut Cpu, op: u32) {
    let imm = (op >> 10) & 1 == 1;
    let sub = (op >> 9) & 1 == 1;
    let rn_or_imm = (op >> 6) & 0x7;
    let rs = ((op >> 3) & 0x7) as usize;
    let rd = (op & 0x7) as usize;
    let operand = if imm { rn_or_imm } else { cpu.r[rn_or_imm as usize] };
    let (result, c, v) = if sub {
        sub_flags(cpu.r[rs], operand)
    } else {
        add_flags(cpu.r[rs], operand)
    };
    cpu.r[rd] = result;
    cpu.set_flag(FLAG_C, c);
    cpu.set_flag(FLAG_V, v);
    cpu.set_flag(FLAG_Z, result == 0);
    cpu.set_flag(FLAG_N, result & 0x8000_0000 != 0);
}

// Format 3
fn mov_cmp_add_sub_imm(cpu: &mut Cpu, op: u32) {
    let sub_op = (op >> 11) & 0x3;
    let rd = ((op >> 8) & 0x7) as usize;
    let imm = op & 0xFF;
    match sub_op {
        0 => {
            // MOV
            cpu.r[rd] = imm;
            cpu.set_flag(FLAG_Z, imm == 0);
            cpu.set_flag(FLAG_N, false);
        }
        1 => {
            // CMP
            let (result, c, v) = sub_flags(cpu.r[rd], imm);
            cpu.set_flag(FLAG_C, c);
            cpu.set_flag(FLAG_V, v);
            cpu.set_flag(FLAG_Z, result == 0);
            cpu.set_flag(FLAG_N, result & 0x8000_0000 != 0);
        }
        2 => {
            // ADD
            let (result, c, v) = add_flags(cpu.r[rd], imm);
            cpu.r[rd] = result;
            cpu.set_flag(FLAG_C, c);
            cpu.set_flag(FLAG_V, v);
            cpu.set_flag(FLAG_Z, result == 0);
            cpu.set_flag(FLAG_N, result & 0x8000_0000 != 0);
        }
        3 => {
            // SUB
            let (result, c, v) = sub_flags(cpu.r[rd], imm);
            cpu.r[rd] = result;
            cpu.set_flag(FLAG_C, c);
            cpu.set_flag(FLAG_V, v);
            cpu.set_flag(FLAG_Z, result == 0);
            cpu.set_flag(FLAG_N, result & 0x8000_0000 != 0);
        }
        _ => unreachable!(),
    }
}

// Format 4: ALU operations
fn alu_ops<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let alu = (op >> 6) & 0xF;
    let rs = ((op >> 3) & 0x7) as usize;
    let rd = (op & 0x7) as usize;
    let a = cpu.r[rd];
    let b = cpu.r[rs];
    let carry_in = cpu.flag(FLAG_C);
    let mut set_c: Option<bool> = None;
    let mut set_v: Option<bool> = None;
    let mut write = true;
    let result = match alu {
        0x0 => a & b,                                   // AND
        0x1 => a ^ b,                                   // EOR
        0x2 => {
            // LSL by reg
            bus.idle(1);
            let (r, c) = apply_shift_reg(0, a, b & 0xFF, carry_in);
            set_c = Some(c);
            r
        }
        0x3 => {
            bus.idle(1);
            let (r, c) = apply_shift_reg(1, a, b & 0xFF, carry_in);
            set_c = Some(c);
            r
        }
        0x4 => {
            bus.idle(1);
            let (r, c) = apply_shift_reg(2, a, b & 0xFF, carry_in);
            set_c = Some(c);
            r
        }
        0x5 => {
            let (r, c, v) = adc_flags(a, b, carry_in);
            set_c = Some(c);
            set_v = Some(v);
            r
        }
        0x6 => {
            let (r, c, v) = sbc_flags(a, b, carry_in);
            set_c = Some(c);
            set_v = Some(v);
            r
        }
        0x7 => {
            bus.idle(1);
            let (r, c) = apply_shift_reg(3, a, b & 0xFF, carry_in);
            set_c = Some(c);
            r
        }
        0x8 => {
            write = false;
            a & b
        } // TST
        0x9 => {
            // NEG
            let (r, c, v) = sub_flags(0, b);
            set_c = Some(c);
            set_v = Some(v);
            r
        }
        0xA => {
            write = false;
            let (r, c, v) = sub_flags(a, b);
            set_c = Some(c);
            set_v = Some(v);
            r
        } // CMP
        0xB => {
            write = false;
            let (r, c, v) = add_flags(a, b);
            set_c = Some(c);
            set_v = Some(v);
            r
        } // CMN
        0xC => a | b,                                   // ORR
        0xD => {
            // MUL
            bus.idle(1);
            a.wrapping_mul(b)
        }
        0xE => a & !b,                                  // BIC
        0xF => !b,                                      // MVN
        _ => unreachable!(),
    };
    if write {
        cpu.r[rd] = result;
    }
    cpu.set_flag(FLAG_Z, result == 0);
    cpu.set_flag(FLAG_N, result & 0x8000_0000 != 0);
    if let Some(c) = set_c {
        cpu.set_flag(FLAG_C, c);
    }
    if let Some(v) = set_v {
        cpu.set_flag(FLAG_V, v);
    }
}

// Format 5: Hi register operations / BX
fn hi_reg_bx<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let alu = (op >> 8) & 0x3;
    let h1 = (op >> 7) & 1;
    let h2 = (op >> 6) & 1;
    let rs = (((op >> 3) & 0x7) | (h2 << 3)) as usize;
    let rd = ((op & 0x7) | (h1 << 3)) as usize;
    let src = if rs == 15 { cpu.r[15] & !1 } else { cpu.r[rs] };
    match alu {
        0 => {
            // ADD (no flags)
            let result = cpu.r[rd].wrapping_add(src);
            if rd == 15 {
                cpu.r[15] = result & !1;
                cpu.flush_pipeline(bus);
            } else {
                cpu.r[rd] = result;
            }
        }
        1 => {
            // CMP (sets flags)
            let (result, c, v) = sub_flags(cpu.r[rd], src);
            cpu.set_flag(FLAG_C, c);
            cpu.set_flag(FLAG_V, v);
            cpu.set_flag(FLAG_Z, result == 0);
            cpu.set_flag(FLAG_N, result & 0x8000_0000 != 0);
        }
        2 => {
            // MOV (no flags)
            if rd == 15 {
                cpu.r[15] = src & !1;
                cpu.flush_pipeline(bus);
            } else {
                cpu.r[rd] = src;
            }
        }
        3 => {
            // BX
            let addr = src;
            cpu.set_flag(FLAG_T, addr & 1 != 0);
            cpu.r[15] = addr;
            cpu.flush_pipeline(bus);
        }
        _ => unreachable!(),
    }
}

// Format 6: PC-relative load
fn pc_relative_load<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let rd = ((op >> 8) & 0x7) as usize;
    let imm = (op & 0xFF) * 4;
    let addr = (cpu.r[15] & !2).wrapping_add(imm);
    let val = bus.read32(addr & !3, Access::NonSeq);
    cpu.r[rd] = val;
    bus.idle(1);
}

// Format 7: load/store with register offset
fn load_store_reg<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let load = (op >> 11) & 1 == 1;
    let byte = (op >> 10) & 1 == 1;
    let ro = ((op >> 6) & 0x7) as usize;
    let rb = ((op >> 3) & 0x7) as usize;
    let rd = (op & 0x7) as usize;
    let addr = cpu.r[rb].wrapping_add(cpu.r[ro]);
    if load {
        cpu.r[rd] = if byte {
            bus.read8(addr, Access::NonSeq) as u32
        } else {
            let aligned = addr & !3;
            let v = bus.read32(aligned, Access::NonSeq);
            v.rotate_right((addr & 3) * 8)
        };
        bus.idle(1);
    } else if byte {
        bus.write8(addr, cpu.r[rd] as u8, Access::NonSeq);
    } else {
        bus.write32(addr & !3, cpu.r[rd], Access::NonSeq);
    }
}

// Format 8: load/store sign-extended byte/halfword
fn load_store_sign_ext<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let sh = (op >> 10) & 0x3;
    let ro = ((op >> 6) & 0x7) as usize;
    let rb = ((op >> 3) & 0x7) as usize;
    let rd = (op & 0x7) as usize;
    let addr = cpu.r[rb].wrapping_add(cpu.r[ro]);
    match sh {
        0 => {
            // STRH
            bus.write16(addr & !1, cpu.r[rd] as u16, Access::NonSeq);
        }
        1 => {
            // LDSB
            cpu.r[rd] = bus.read8(addr, Access::NonSeq) as i8 as i32 as u32;
            bus.idle(1);
        }
        2 => {
            // LDRH
            let aligned = addr & !1;
            let v = bus.read16(aligned, Access::NonSeq) as u32;
            cpu.r[rd] = if addr & 1 != 0 { v.rotate_right(8) } else { v };
            bus.idle(1);
        }
        3 => {
            // LDSH (if misaligned, acts like LDSB)
            cpu.r[rd] = if addr & 1 != 0 {
                bus.read8(addr, Access::NonSeq) as i8 as i32 as u32
            } else {
                bus.read16(addr, Access::NonSeq) as i16 as i32 as u32
            };
            bus.idle(1);
        }
        _ => unreachable!(),
    }
}

// Format 9: load/store with immediate offset
fn load_store_imm<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let byte = (op >> 12) & 1 == 1;
    let load = (op >> 11) & 1 == 1;
    let offset5 = (op >> 6) & 0x1F;
    let rb = ((op >> 3) & 0x7) as usize;
    let rd = (op & 0x7) as usize;
    let offset = if byte { offset5 } else { offset5 << 2 };
    let addr = cpu.r[rb].wrapping_add(offset);
    if load {
        cpu.r[rd] = if byte {
            bus.read8(addr, Access::NonSeq) as u32
        } else {
            let aligned = addr & !3;
            let v = bus.read32(aligned, Access::NonSeq);
            v.rotate_right((addr & 3) * 8)
        };
        bus.idle(1);
    } else if byte {
        bus.write8(addr, cpu.r[rd] as u8, Access::NonSeq);
    } else {
        bus.write32(addr & !3, cpu.r[rd], Access::NonSeq);
    }
}

// Format 10: load/store halfword
fn load_store_half<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let load = (op >> 11) & 1 == 1;
    let offset = ((op >> 6) & 0x1F) << 1;
    let rb = ((op >> 3) & 0x7) as usize;
    let rd = (op & 0x7) as usize;
    let addr = cpu.r[rb].wrapping_add(offset);
    if load {
        let aligned = addr & !1;
        let v = bus.read16(aligned, Access::NonSeq) as u32;
        cpu.r[rd] = if addr & 1 != 0 { v.rotate_right(8) } else { v };
        bus.idle(1);
    } else {
        bus.write16(addr & !1, cpu.r[rd] as u16, Access::NonSeq);
    }
}

// Format 11: SP-relative load/store
fn sp_relative<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let load = (op >> 11) & 1 == 1;
    let rd = ((op >> 8) & 0x7) as usize;
    let offset = (op & 0xFF) << 2;
    let addr = cpu.r[13].wrapping_add(offset);
    if load {
        let aligned = addr & !3;
        let v = bus.read32(aligned, Access::NonSeq);
        cpu.r[rd] = v.rotate_right((addr & 3) * 8);
        bus.idle(1);
    } else {
        bus.write32(addr & !3, cpu.r[rd], Access::NonSeq);
    }
}

// Format 12: load address
fn load_address(cpu: &mut Cpu, op: u32) {
    let sp = (op >> 11) & 1 == 1;
    let rd = ((op >> 8) & 0x7) as usize;
    let offset = (op & 0xFF) << 2;
    cpu.r[rd] = if sp {
        cpu.r[13].wrapping_add(offset)
    } else {
        (cpu.r[15] & !2).wrapping_add(offset)
    };
}

// Format 13: add offset to stack pointer
fn add_sp_offset(cpu: &mut Cpu, op: u32) {
    let offset = (op & 0x7F) << 2;
    if (op >> 7) & 1 == 1 {
        cpu.r[13] = cpu.r[13].wrapping_sub(offset);
    } else {
        cpu.r[13] = cpu.r[13].wrapping_add(offset);
    }
}

// Format 14: push/pop registers
fn push_pop<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let load = (op >> 11) & 1 == 1; // pop
    let pc_lr = (op >> 8) & 1 == 1;
    let reg_list = op & 0xFF;
    let mut access = Access::NonSeq;

    if load {
        // POP: read ascending from SP.
        let mut addr = cpu.r[13];
        for i in 0..8 {
            if reg_list & (1 << i) != 0 {
                cpu.r[i] = bus.read32(addr & !3, access);
                access = Access::Seq;
                addr = addr.wrapping_add(4);
            }
        }
        if pc_lr {
            let v = bus.read32(addr & !3, access);
            cpu.set_flag(FLAG_T, v & 1 != 0);
            cpu.r[15] = v & !1;
            cpu.flush_pipeline(bus);
            addr = addr.wrapping_add(4);
        }
        cpu.r[13] = addr;
        bus.idle(1);
    } else {
        // PUSH: compute count, write ascending from low address.
        let mut count = reg_list.count_ones();
        if pc_lr {
            count += 1;
        }
        let mut addr = cpu.r[13].wrapping_sub(count * 4);
        cpu.r[13] = addr;
        for i in 0..8 {
            if reg_list & (1 << i) != 0 {
                bus.write32(addr & !3, cpu.r[i], access);
                access = Access::Seq;
                addr = addr.wrapping_add(4);
            }
        }
        if pc_lr {
            bus.write32(addr & !3, cpu.r[14], access);
        }
    }
}

// Format 15: multiple load/store
fn block_transfer<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let load = (op >> 11) & 1 == 1;
    let rb = ((op >> 8) & 0x7) as usize;
    let reg_list = op & 0xFF;
    let mut addr = cpu.r[rb];
    let mut access = Access::NonSeq;

    if reg_list == 0 {
        // Empty list quirk: transfers r15, base += 0x40.
        if load {
            let v = bus.read32(addr & !3, Access::NonSeq);
            cpu.r[15] = v & !1;
            cpu.flush_pipeline(bus);
        } else {
            bus.write32(addr & !3, cpu.r[15].wrapping_add(2), Access::NonSeq);
        }
        cpu.r[rb] = addr.wrapping_add(0x40);
        return;
    }

    let writeback_val = addr.wrapping_add(reg_list.count_ones() * 4);
    let rb_in_list = reg_list & (1 << rb) != 0;
    let rb_first = rb_in_list && (reg_list & ((1 << rb) - 1)) == 0;

    if load {
        for i in 0..8 {
            if reg_list & (1 << i) != 0 {
                cpu.r[i] = bus.read32(addr & !3, access);
                access = Access::Seq;
                addr = addr.wrapping_add(4);
            }
        }
        bus.idle(1);
        if !rb_in_list {
            cpu.r[rb] = writeback_val;
        }
    } else {
        let mut idx = 0;
        for i in 0..8 {
            if reg_list & (1 << i) != 0 {
                let v = if i == rb && !rb_first {
                    writeback_val
                } else {
                    cpu.r[i]
                };
                bus.write32(addr & !3, v, access);
                access = Access::Seq;
                addr = addr.wrapping_add(4);
                idx += 1;
                let _ = idx;
            }
        }
        cpu.r[rb] = writeback_val;
    }
}

// Format 16: conditional branch
fn cond_branch<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32, cond: u32) {
    if cond_passed(cpu, cond) {
        let offset = ((op & 0xFF) as i8 as i32) << 1;
        cpu.r[15] = (cpu.r[15] as i32).wrapping_add(offset) as u32;
        cpu.flush_pipeline(bus);
    }
}

// Format 18: unconditional branch
fn uncond_branch<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let offset = (((op & 0x7FF) << 1) as i32) << 20 >> 20; // sign-extend 12-bit
    cpu.r[15] = (cpu.r[15] as i32).wrapping_add(offset) as u32;
    cpu.flush_pipeline(bus);
}

// Format 19: long branch with link
fn long_branch_link<B: Bus>(cpu: &mut Cpu, bus: &mut B, op: u32) {
    let h = (op >> 11) & 1;
    if h == 0 {
        // First instruction: LR = PC + (offset_high << 12), sign-extended.
        let offset = (((op & 0x7FF) << 12) as i32) << 9 >> 9;
        cpu.r[14] = (cpu.r[15] as i32).wrapping_add(offset) as u32;
    } else {
        // Second instruction: PC = LR + (offset_low << 1); LR = ret | 1.
        let next = cpu.r[15].wrapping_sub(2) | 1;
        cpu.r[15] = cpu.r[14].wrapping_add((op & 0x7FF) << 1);
        cpu.r[14] = next;
        cpu.flush_pipeline(bus);
    }
}
