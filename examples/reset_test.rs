//! Verify emu_reset produces identical state to a fresh load.
fn main() {
    let rom = std::fs::read(std::env::args().nth(1).unwrap()).unwrap();
    gba_emu::emu_init();
    let buf = gba_emu::emu_rom_buffer();
    unsafe { std::ptr::copy_nonoverlapping(rom.as_ptr(), buf, rom.len()); }
    gba_emu::emu_load_rom(rom.len() as i32);

    // Run 90 frames, capture framebuffer.
    for _ in 0..90 { gba_emu::emu_run_frame(); let _ = gba_emu::emu_audio_samples(); }
    let fb1: Vec<u32> = unsafe {
        let p = gba_emu::emu_framebuffer();
        (0..240*160).map(|i| *p.add(i)).collect()
    };

    // Reset, run the same 90 frames, capture again.
    gba_emu::emu_reset();
    for _ in 0..90 { gba_emu::emu_run_frame(); let _ = gba_emu::emu_audio_samples(); }
    let fb2: Vec<u32> = unsafe {
        let p = gba_emu::emu_framebuffer();
        (0..240*160).map(|i| *p.add(i)).collect()
    };

    let diff = fb1.iter().zip(&fb2).filter(|(a,b)| a != b).count();
    println!("reset determinism: {} / {} pixels differ", diff, fb1.len());
}
