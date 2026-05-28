//! GBA emulator — wasm cdylib implementing the eval ABI.
#![allow(clippy::missing_safety_doc)]

mod bus;
mod cpu;
mod dma;
mod gba;
mod ppu;
mod apu;
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
