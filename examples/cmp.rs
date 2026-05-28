//! Native test harness: run the emulator and dump frames as PPM + audio info.
//! Usage: cargo run --release --example cmp -- <rom> <frames> <outdir> [replay]

use std::io::Write;

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 4 {
        eprintln!("usage: cmp <rom> <frames> <outdir> [replay]");
        std::process::exit(1);
    }
    let rom_path = &args[1];
    let frames: u32 = args[2].parse().unwrap();
    let outdir = &args[3];
    let replay: Vec<(u32, u32)> = if args.len() > 4 {
        let txt = std::fs::read_to_string(&args[4]).unwrap();
        txt.lines()
            .filter(|l| !l.trim().is_empty())
            .map(|l| {
                let mut it = l.split_whitespace();
                let f: u32 = it.next().unwrap().parse().unwrap();
                let k = it.next().unwrap();
                let k = u32::from_str_radix(k.trim_start_matches("0x"), 16).unwrap();
                (f, k)
            })
            .collect()
    } else {
        Vec::new()
    };

    std::fs::create_dir_all(outdir).unwrap();
    let rom = std::fs::read(rom_path).unwrap();

    gba_emu::emu_init();
    let buf = gba_emu::emu_rom_buffer();
    unsafe {
        std::ptr::copy_nonoverlapping(rom.as_ptr(), buf, rom.len());
    }
    gba_emu::emu_load_rom(rom.len() as i32);

    let mut keys = 0u32;
    let mut total_audio = 0usize;
    for f in 0..frames {
        for (rf, rk) in &replay {
            if *rf == f {
                keys = *rk;
            }
        }
        gba_emu::emu_set_keys(keys);
        gba_emu::emu_run_frame();
        let n = gba_emu::emu_audio_samples();
        total_audio += n as usize;

        // Dump only the final frame and a few checkpoints to save space.
        if std::env::var("ALLF").is_ok() || f + 1 == frames || frames <= 10 || f % 60 == 0 {
            let fb = gba_emu::emu_framebuffer();
            let path = format!("{}/frame_{:05}.ppm", outdir, f);
            dump_ppm(&path, fb);
        }
        if std::env::var("DBG").is_ok() {
            let s = gba_emu::debug_state();
            let r = gba_emu::debug_regs();
            eprintln!("f{} dispcnt={:04x} waitcnt={:04x} pc={:08x} insns={} cyc={} r0={:08x} r1={:08x} r2={:08x}",
                f, s[0], s[15], s[9], gba_emu::debug_insns(), gba_emu::debug_cycles(), r[0], r[1], r[2]);
        }
    }
    println!("frames={} audio_pairs_last_call_total~={}", frames, total_audio);
}

fn dump_ppm(path: &str, fb: *const u32) {
    let mut out = Vec::with_capacity(240 * 160 * 3 + 32);
    out.extend_from_slice(format!("P6\n240 160\n255\n").as_bytes());
    unsafe {
        for i in 0..240 * 160 {
            let px = *fb.add(i);
            let r = (px & 0xFF) as u8;
            let g = ((px >> 8) & 0xFF) as u8;
            let b = ((px >> 16) & 0xFF) as u8;
            out.push(r);
            out.push(g);
            out.push(b);
        }
    }
    let mut f = std::fs::File::create(path).unwrap();
    f.write_all(&out).unwrap();
}
