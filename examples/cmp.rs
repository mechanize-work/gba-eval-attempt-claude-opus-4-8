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

    if let Ok(m) = std::env::var("LAYERMASK") {
        gba_emu::debug_set_layer_mask(u32::from_str_radix(m.trim_start_matches("0x"), 16).unwrap());
    }
    let mut keys = 0u32;
    let mut total_audio = 0usize;
    let mut audio_out: Vec<i16> = Vec::new();
    for f in 0..frames {
        for (rf, rk) in &replay {
            if *rf == f {
                keys = *rk;
            }
        }
        gba_emu::emu_set_keys(keys);
        gba_emu::emu_run_frame();
        let n = gba_emu::emu_audio_samples();
        if n > 0 {
            let buf = gba_emu::emu_audio_buffer();
            unsafe {
                for i in 0..(n as usize * 2) {
                    audio_out.push(*buf.add(i));
                }
            }
        }
        total_audio += n as usize;

        // Dump only the final frame and a few checkpoints to save space.
        if std::env::var("ALLF").is_ok() || f + 1 == frames || frames <= 10 || f % 60 == 0 {
            let fb = gba_emu::emu_framebuffer();
            let path = format!("{}/frame_{:05}.ppm", outdir, f);
            dump_ppm(&path, fb);
        }
        if std::env::var("PPU").is_ok() && (f==130 || f==149 || f==170 || f+1==frames) {
            let q=gba_emu::debug_ppu();
            eprintln!("PPU dispcnt={:04x} bldcnt={:04x} bldalpha={:04x} bldy={:04x} winin={:04x} winout={:04x} winh0={:04x} winv0={:04x} bg0c={:04x} bg1c={:04x} bg2c={:04x} bg3c={:04x}",q[0],q[1],q[2],q[3],q[4],q[5],q[6],q[7],q[8],q[9],q[10],q[11]);
            let r=gba_emu::debug_ppu2();
            eprintln!("    hofs0={} vofs0={} hofs1={} vofs1={} hofs2={} vofs2={} hofs3={} vofs3={} mosaic={:04x} winh1={:04x} winv1={:04x}",r[0],r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8],r[9],r[10]);
        }
        if std::env::var("TMR").is_ok() && f%30==0 {
            let s=gba_emu::debug_state();
            eprintln!("f{} ie={:04x} if={:04x} ime={}", f, s[11], s[12], s[13]);
        }
        if std::env::var("SND").is_ok() && (f%40==0 || f+1==frames) {
            let a=gba_emu::debug_apu();
            eprintln!("f{} sndcnt_l={:04x} sndcnt_h={:04x} master={} chans={:04b} fifoA={} fifoB={}",f,a[0],a[1],a[7],a[4],a[5],a[6]);
        }
        if std::env::var("DBG").is_ok() {
            let s = gba_emu::debug_state();
            let r = gba_emu::debug_regs();
            eprintln!("f{} dispcnt={:04x} waitcnt={:04x} pc={:08x} insns={} cyc={} r0={:08x} r1={:08x} r2={:08x}",
                f, s[0], s[15], s[9], gba_emu::debug_insns(), gba_emu::debug_cycles(), r[0], r[1], r[2]);
        }
    }
    if let Ok(ap) = std::env::var("AUDIO_OUT") {
        let mut raw = Vec::with_capacity(audio_out.len()*2);
        for s in &audio_out { raw.extend_from_slice(&s.to_le_bytes()); }
        std::fs::write(&ap, &raw).unwrap();
        eprintln!("wrote {} stereo pairs to {}", audio_out.len()/2, ap);
    }
    println!("frames={} audio_pairs_last_call_total~={} rate={}", frames, total_audio, gba_emu::emu_audio_rate());
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
