//! GBA emulator — wasm cdylib implementing the eval ABI.
#![allow(clippy::missing_safety_doc)]

mod bus;
mod cpu;
mod dma;
mod gba;
mod io;
mod ppu;
mod apu;
mod sound;
mod timer;
mod sched;

use gba::Gba;

const ROM_BUFFER_SIZE: usize = 32 * 1024 * 1024;

// Global emulator state. Single-threaded wasm, so a static mut is fine.
static mut EMU: Option<Box<Gba>> = None;
static mut ROM_BUF: Option<Box<[u8]>> = None;

fn emu() -> &'static mut Gba {
    unsafe {
        let e = core::ptr::addr_of_mut!(EMU);
        (*e).as_mut().expect("emu not initialized")
    }
}

#[no_mangle]
pub extern "C" fn emu_init() -> i32 {
    unsafe {
        let rb = core::ptr::addr_of_mut!(ROM_BUF);
        if (*rb).is_none() {
            *rb = Some(vec![0u8; ROM_BUFFER_SIZE].into_boxed_slice());
        }
        let e = core::ptr::addr_of_mut!(EMU);
        *e = Some(Box::new(Gba::new()));
    }
    1
}

#[no_mangle]
pub extern "C" fn emu_rom_buffer() -> *mut u8 {
    unsafe {
        let rb = core::ptr::addr_of_mut!(ROM_BUF);
        if (*rb).is_none() {
            *rb = Some(vec![0u8; ROM_BUFFER_SIZE].into_boxed_slice());
        }
        (*rb).as_mut().unwrap().as_mut_ptr()
    }
}

#[no_mangle]
pub extern "C" fn emu_load_rom(len: i32) -> i32 {
    let len = len.max(0) as usize;
    unsafe {
        let rb = core::ptr::addr_of_mut!(ROM_BUF);
        let rom = match (*rb).as_ref() {
            Some(b) => &b[..len.min(ROM_BUFFER_SIZE)],
            None => return 0,
        };
        let g = emu();
        g.load_rom(rom);
    }
    1
}

#[no_mangle]
pub extern "C" fn emu_reset() -> i32 {
    emu().reset();
    1
}

#[no_mangle]
pub extern "C" fn emu_set_keys(k: u32) {
    emu().set_keys(k);
}

#[no_mangle]
pub extern "C" fn emu_run_frame() {
    emu().run_frame();
}

#[no_mangle]
pub extern "C" fn emu_framebuffer() -> *const u32 {
    emu().framebuffer().as_ptr()
}

#[no_mangle]
pub extern "C" fn emu_audio_buffer() -> *const i16 {
    emu().audio_buffer()
}

#[no_mangle]
pub extern "C" fn emu_audio_samples() -> i32 {
    emu().audio_samples()
}

#[no_mangle]
pub extern "C" fn emu_audio_rate() -> i32 {
    emu().audio_rate()
}

/// Debug: returns a pointer to a small array of key PPU/CPU registers.
/// [dispcnt, dispstat, vcount, bg0cnt..bg3cnt, bg0hofs, mode-detect...]
pub fn debug_state() -> [u32; 16] {
    let g = emu();
    let p = &g.bus.ppu;
    [
        p.dispcnt as u32,
        p.dispstat as u32,
        p.vcount as u32,
        p.bgcnt[0] as u32,
        p.bgcnt[1] as u32,
        p.bgcnt[2] as u32,
        p.bgcnt[3] as u32,
        p.bghofs[0] as u32,
        p.bgvofs[0] as u32,
        g.cpu.r[15],
        g.cpu.cpsr,
        g.bus.ie as u32,
        g.bus.if_ as u32,
        g.bus.ime as u32,
        p.bldcnt as u32,
        g.bus.waitcnt as u32,
    ]
}

pub fn debug_cycles() -> u64 {
    emu().bus.sched.now
}

pub fn debug_insns() -> u64 {
    emu().insn_count
}

pub fn debug_regs() -> [u32; 16] {
    emu().cpu.r
}

pub fn debug_ppu() -> [u32; 12] {
    let p = &emu().bus.ppu;
    [
        p.dispcnt as u32, p.bldcnt as u32, p.bldalpha as u32, p.bldy as u32,
        p.winin as u32, p.winout as u32, p.winh[0] as u32, p.winv[0] as u32,
        p.bgcnt[0] as u32, p.bgcnt[1] as u32, p.bgcnt[2] as u32, p.bgcnt[3] as u32,
    ]
}
