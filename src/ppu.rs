//! Picture Processing Unit — scanline renderer.

pub const HDRAW: u32 = 240;
pub const VDRAW: u32 = 160;
pub const TOTAL_LINES: u32 = 228;
pub const CYCLES_PER_LINE: u32 = 1232;
pub const HBLANK_START: u32 = 1006; // approx; HDRAW ~ 960, but mesen uses 1006 for hblank flag

pub const SCREEN_W: usize = 240;
pub const SCREEN_H: usize = 160;

#[derive(Clone)]
pub struct Ppu {
    // Memory
    pub palette: Box<[u8]>, // 1 KiB
    pub vram: Box<[u8]>,    // 96 KiB
    pub oam: Box<[u8]>,     // 1 KiB

    // Registers
    pub dispcnt: u16,
    pub green_swap: u16,
    pub dispstat: u16,
    pub vcount: u16,
    pub bgcnt: [u16; 4],
    pub bghofs: [u16; 4],
    pub bgvofs: [u16; 4],
    // Affine params for BG2/BG3 (index 0 => BG2, 1 => BG3)
    pub bg_pa: [i16; 2],
    pub bg_pb: [i16; 2],
    pub bg_pc: [i16; 2],
    pub bg_pd: [i16; 2],
    pub bg_x: [i32; 2],   // reference point X (28-bit signed, fixed .8)
    pub bg_y: [i32; 2],
    pub bg_x_latch: [i32; 2], // internal accumulators
    pub bg_y_latch: [i32; 2],
    pub winh: [u16; 2],
    pub winv: [u16; 2],
    pub winin: u16,
    pub winout: u16,
    pub mosaic: u16,
    pub bldcnt: u16,
    pub bldalpha: u16,
    pub bldy: u16,

    // State
    pub dot: u32,         // cycles into current scanline
    pub frame: Box<[u32]>, // 240*160 output
    pub debug_layer_mask: u32, // bit per layer: 0-3 bg, 4 obj (debug only); 0xFF=all

    // Per-line scratch buffers.
    line_bg: [[u16; SCREEN_W]; 4], // color index per bg (with palette resolved to 15-bit | flags)
    bg_drawn: [[bool; SCREEN_W]; 4],
    // sprite line: color (15-bit), priority, and flags
    obj_color: [u16; SCREEN_W],
    obj_prio: [u8; SCREEN_W],
    obj_window: [bool; SCREEN_W],
    obj_semi: [bool; SCREEN_W], // semi-transparent (alpha-blend obj)
    obj_drawn: [bool; SCREEN_W],
}

const TRANSPARENT: u16 = 0x8000_u16; // sentinel high bit (palette colors are 15-bit, so bit15 free)

impl Ppu {
    pub fn new() -> Self {
        Ppu {
            palette: vec![0u8; 1024].into_boxed_slice(),
            vram: vec![0u8; 96 * 1024].into_boxed_slice(),
            oam: vec![0u8; 1024].into_boxed_slice(),
            dispcnt: 0x80,
            green_swap: 0,
            dispstat: 0,
            vcount: 0,
            bgcnt: [0; 4],
            bghofs: [0; 4],
            bgvofs: [0; 4],
            bg_pa: [0x100, 0x100],
            bg_pb: [0; 2],
            bg_pc: [0; 2],
            bg_pd: [0x100, 0x100],
            bg_x: [0; 2],
            bg_y: [0; 2],
            bg_x_latch: [0; 2],
            bg_y_latch: [0; 2],
            winh: [0; 2],
            winv: [0; 2],
            winin: 0,
            winout: 0,
            mosaic: 0,
            bldcnt: 0,
            bldalpha: 0,
            bldy: 0,
            dot: 0,
            frame: vec![0xFF00_0000u32; SCREEN_W * SCREEN_H].into_boxed_slice(),
            debug_layer_mask: 0xFF,
            line_bg: [[0; SCREEN_W]; 4],
            bg_drawn: [[false; SCREEN_W]; 4],
            obj_color: [0; SCREEN_W],
            obj_prio: [0; SCREEN_W],
            obj_window: [false; SCREEN_W],
            obj_semi: [false; SCREEN_W],
            obj_drawn: [false; SCREEN_W],
        }
    }

    pub fn reset(&mut self) {
        for b in self.palette.iter_mut() { *b = 0; }
        for b in self.vram.iter_mut() { *b = 0; }
        for b in self.oam.iter_mut() { *b = 0; }
        // BIOS leaves forced-blank (DISPCNT bit 7) on after boot, so the screen is
        // white until the game first writes DISPCNT (matches oracle's boot frames).
        self.dispcnt = 0x80;
        self.dispstat = 0;
        self.vcount = 0;
        self.bgcnt = [0; 4];
        self.bghofs = [0; 4];
        self.bgvofs = [0; 4];
        self.bg_pa = [0x100, 0x100];
        self.bg_pb = [0; 2];
        self.bg_pc = [0; 2];
        self.bg_pd = [0x100, 0x100];
        self.bg_x = [0; 2];
        self.bg_y = [0; 2];
        self.bg_x_latch = [0; 2];
        self.bg_y_latch = [0; 2];
        self.winh = [0; 2];
        self.winv = [0; 2];
        self.winin = 0;
        self.winout = 0;
        self.mosaic = 0;
        self.bldcnt = 0;
        self.bldalpha = 0;
        self.bldy = 0;
        self.dot = 0;
        for p in self.frame.iter_mut() { *p = 0xFF00_0000; }
    }

    #[inline]
    fn pal16(&self, idx: usize) -> u16 {
        u16::from_le_bytes([self.palette[idx * 2], self.palette[idx * 2 + 1]]) & 0x7FFF
    }

    #[inline]
    fn vram16(&self, addr: usize) -> u16 {
        u16::from_le_bytes([self.vram[addr], self.vram[addr + 1]])
    }

    /// Latch affine reference points at the start of a frame.
    pub fn latch_affine_frame(&mut self) {
        for i in 0..2 {
            self.bg_x_latch[i] = self.bg_x[i];
            self.bg_y_latch[i] = self.bg_y[i];
        }
    }

    /// Advance internal affine accumulators after a scanline.
    pub fn step_affine_line(&mut self) {
        for i in 0..2 {
            self.bg_x_latch[i] = self.bg_x_latch[i].wrapping_add(self.bg_pb[i] as i32);
            self.bg_y_latch[i] = self.bg_y_latch[i].wrapping_add(self.bg_pd[i] as i32);
        }
    }

    // --- Color conversion -------------------------------------------------
    #[inline]
    fn to_rgba(color15: u16) -> u32 {
        let r = (color15 & 0x1F) as u32;
        let g = ((color15 >> 5) & 0x1F) as u32;
        let b = ((color15 >> 10) & 0x1F) as u32;
        let r8 = (r << 3) | (r >> 2);
        let g8 = (g << 3) | (g >> 2);
        let b8 = (b << 3) | (b >> 2);
        0xFF00_0000 | (b8 << 16) | (g8 << 8) | r8
    }

    // --- Scanline rendering ----------------------------------------------
    pub fn render_scanline(&mut self, line: u32) {
        if line >= VDRAW {
            return;
        }
        let mode = (self.dispcnt & 0x7) as u32;
        let forced_blank = self.dispcnt & 0x80 != 0;

        // Reset scratch.
        for bg in 0..4 {
            for x in 0..SCREEN_W {
                self.bg_drawn[bg][x] = false;
            }
        }
        for x in 0..SCREEN_W {
            self.obj_drawn[x] = false;
            self.obj_window[x] = false;
            self.obj_semi[x] = false;
            self.obj_prio[x] = 4;
        }

        if forced_blank {
            let off = (line as usize) * SCREEN_W;
            for x in 0..SCREEN_W {
                self.frame[off + x] = 0xFFFF_FFFF;
            }
            return;
        }

        // Render objects if enabled.
        if self.dispcnt & 0x1000 != 0 {
            self.render_objects(line);
        }

        match mode {
            0 => {
                for bg in 0..4 {
                    if self.dispcnt & (1 << (8 + bg)) != 0 {
                        self.render_text_bg(bg, line);
                    }
                }
            }
            1 => {
                if self.dispcnt & 0x100 != 0 { self.render_text_bg(0, line); }
                if self.dispcnt & 0x200 != 0 { self.render_text_bg(1, line); }
                if self.dispcnt & 0x400 != 0 { self.render_affine_bg(2, line); }
            }
            2 => {
                if self.dispcnt & 0x400 != 0 { self.render_affine_bg(2, line); }
                if self.dispcnt & 0x800 != 0 { self.render_affine_bg(3, line); }
            }
            3 => {
                if self.dispcnt & 0x400 != 0 { self.render_mode3(line); }
            }
            4 => {
                if self.dispcnt & 0x400 != 0 { self.render_mode4(line); }
            }
            5 => {
                if self.dispcnt & 0x400 != 0 { self.render_mode5(line); }
            }
            _ => {}
        }

        self.compose(line, mode);
    }

    fn render_text_bg(&mut self, bg: usize, line: u32) {
        let cnt = self.bgcnt[bg];
        let priority = (cnt & 0x3) as u8;
        let _ = priority;
        let char_base = (((cnt >> 2) & 0x3) as usize) * 0x4000;
        let mosaic = cnt & 0x40 != 0;
        let color256 = cnt & 0x80 != 0;
        let screen_base = (((cnt >> 8) & 0x1F) as usize) * 0x800;
        let size = (cnt >> 14) & 0x3;

        let (width, height) = match size {
            0 => (256u32, 256u32),
            1 => (512, 256),
            2 => (256, 512),
            3 => (512, 512),
            _ => (256, 256),
        };

        let (mos_h, mos_v) = if mosaic {
            (((self.mosaic & 0xF) as u32) + 1, (((self.mosaic >> 4) & 0xF) as u32) + 1)
        } else {
            (1, 1)
        };

        // Apply vertical mosaic to the screen line before adding scroll.
        let mline = if mos_v > 1 { line - (line % mos_v) } else { line };
        let mut y = mline.wrapping_add(self.bgvofs[bg] as u32);
        y &= height - 1;

        let tile_y = (y / 8) % 32;
        let in_tile_y = y % 8;
        let quadrant_y = (y / 256) & 1;

        for sx in 0..SCREEN_W as u32 {
            // Apply horizontal mosaic to the screen x before adding scroll.
            let msx = if mos_h > 1 { sx - (sx % mos_h) } else { sx };
            let mut x = msx.wrapping_add(self.bghofs[bg] as u32);
            x &= width - 1;
            let tile_x = (x / 8) % 32;
            let in_tile_x = x % 8;
            let quadrant_x = (x / 256) & 1;

            // Determine screenblock based on size.
            let mut sb = screen_base;
            match size {
                1 => sb += (quadrant_x as usize) * 0x800,
                2 => sb += (quadrant_y as usize) * 0x800,
                3 => sb += ((quadrant_y * 2 + quadrant_x) as usize) * 0x800,
                _ => {}
            }
            let map_idx = sb + ((tile_y * 32 + tile_x) as usize) * 2;
            if map_idx + 1 >= self.vram.len() {
                continue;
            }
            let entry = self.vram16(map_idx);
            let tile_num = (entry & 0x3FF) as usize;
            let hflip = entry & 0x400 != 0;
            let vflip = entry & 0x800 != 0;
            let pal_bank = ((entry >> 12) & 0xF) as usize;

            let mut tx = in_tile_x;
            let mut ty = in_tile_y;
            if hflip { tx = 7 - tx; }
            if vflip { ty = 7 - ty; }

            let color = if color256 {
                let addr = char_base + tile_num * 64 + (ty * 8 + tx) as usize;
                if addr >= self.vram.len() { 0 } else {
                    let idx = self.vram[addr] as usize;
                    if idx == 0 { TRANSPARENT } else { self.pal16(idx) }
                }
            } else {
                let addr = char_base + tile_num * 32 + (ty * 4 + tx / 2) as usize;
                if addr >= self.vram.len() { 0 } else {
                    let byte = self.vram[addr];
                    let idx = if tx & 1 == 0 { byte & 0xF } else { byte >> 4 } as usize;
                    if idx == 0 { TRANSPARENT } else { self.pal16(pal_bank * 16 + idx) }
                }
            };
            if color != TRANSPARENT {
                self.line_bg[bg][sx as usize] = color;
                self.bg_drawn[bg][sx as usize] = true;
            }
        }
    }

    fn render_affine_bg(&mut self, bg: usize, line: u32) {
        let idx = bg - 2;
        let cnt = self.bgcnt[bg];
        let char_base = (((cnt >> 2) & 0x3) as usize) * 0x4000;
        let screen_base = (((cnt >> 8) & 0x1F) as usize) * 0x800;
        let wrap = cnt & 0x2000 != 0;
        let size = (cnt >> 14) & 0x3;
        let map_size: u32 = match size { 0 => 128, 1 => 256, 2 => 512, _ => 1024 };
        let tiles = map_size / 8;

        let (mos_h, _mvoff, mut cx, mut cy) = self.affine_mosaic_setup(idx, line);
        let pa = self.bg_pa[idx] as i32;
        let pc = self.bg_pc[idx] as i32;
        let (mut stx, mut sty) = (0i32, 0i32);

        for sx in 0..SCREEN_W {
            if sx as i32 % mos_h == 0 { stx = cx >> 8; sty = cy >> 8; }
            cx = cx.wrapping_add(pa);
            cy = cy.wrapping_add(pc);

            let (px, py) = if wrap {
                (stx.rem_euclid(map_size as i32) as u32, sty.rem_euclid(map_size as i32) as u32)
            } else {
                if stx < 0 || sty < 0 || stx >= map_size as i32 || sty >= map_size as i32 {
                    continue;
                }
                (stx as u32, sty as u32)
            };
            let map_idx = screen_base + (py / 8 * tiles + px / 8) as usize;
            if map_idx >= self.vram.len() { continue; }
            let tile_num = self.vram[map_idx] as usize;
            let addr = char_base + tile_num * 64 + ((py % 8) * 8 + (px % 8)) as usize;
            if addr >= self.vram.len() { continue; }
            let cidx = self.vram[addr] as usize;
            if cidx != 0 {
                self.line_bg[bg][sx] = self.pal16(cidx);
                self.bg_drawn[bg][sx] = true;
            }
        }
    }

    fn render_mode3(&mut self, line: u32) {
        // Bitmap modes are BG2 (an affine BG): sample through the affine matrix.
        // Identity (PA=PD=256, ref=0) reduces to the 1:1 case.
        let (mos_h, mvoff, mut cx, mut cy) = self.affine_mosaic_setup(0, line);
        let pa = self.bg_pa[0] as i32;
        let pc = self.bg_pc[0] as i32;
        let _ = mvoff;
        let (mut stx, mut sty) = (0i32, 0i32);
        for x in 0..SCREEN_W {
            if x as i32 % mos_h == 0 { stx = cx >> 8; sty = cy >> 8; }
            cx = cx.wrapping_add(pa);
            cy = cy.wrapping_add(pc);
            if stx < 0 || sty < 0 || stx >= 240 || sty >= 160 { continue; }
            let addr = (sty as usize * 240 + stx as usize) * 2;
            let color = self.vram16(addr) & 0x7FFF;
            self.line_bg[2][x] = color;
            self.bg_drawn[2][x] = true;
        }
    }

    /// Common affine+mosaic setup: returns (horizontal mosaic step, vertical
    /// offset into the block, and the starting cx/cy with the reference rewound
    /// to the block-top line for vertical mosaic). idx 0=BG2, 1=BG3.
    fn affine_mosaic_setup(&self, idx: usize, line: u32) -> (i32, i32, i32, i32) {
        let bg = idx + 2;
        let (mos_h, mos_v) = if self.bgcnt[bg] & 0x40 != 0 {
            (((self.mosaic & 0xF) as i32) + 1, (((self.mosaic >> 4) & 0xF) as i32) + 1)
        } else {
            (1, 1)
        };
        let mvoff = (line as i32) % mos_v;
        let cx = self.bg_x_latch[idx].wrapping_sub(mvoff.wrapping_mul(self.bg_pb[idx] as i32));
        let cy = self.bg_y_latch[idx].wrapping_sub(mvoff.wrapping_mul(self.bg_pd[idx] as i32));
        (mos_h, mvoff, cx, cy)
    }

    fn render_mode4(&mut self, line: u32) {
        let frame_sel: usize = if self.dispcnt & 0x10 != 0 { 0xA000 } else { 0 };
        let (mos_h, _mvoff, mut cx, mut cy) = self.affine_mosaic_setup(0, line);
        let pa = self.bg_pa[0] as i32;
        let pc = self.bg_pc[0] as i32;
        let (mut stx, mut sty) = (0i32, 0i32);
        for x in 0..SCREEN_W {
            if x as i32 % mos_h == 0 { stx = cx >> 8; sty = cy >> 8; }
            cx = cx.wrapping_add(pa);
            cy = cy.wrapping_add(pc);
            if stx < 0 || sty < 0 || stx >= 240 || sty >= 160 { continue; }
            let idx = self.vram[frame_sel + sty as usize * 240 + stx as usize] as usize;
            if idx != 0 {
                self.line_bg[2][x] = self.pal16(idx);
                self.bg_drawn[2][x] = true;
            }
        }
    }

    fn render_mode5(&mut self, line: u32) {
        // Mode 5 bitmap is 160x128, sampled through the BG2 affine matrix.
        let frame_sel: usize = if self.dispcnt & 0x10 != 0 { 0xA000 } else { 0 };
        let (mos_h, _mvoff, mut cx, mut cy) = self.affine_mosaic_setup(0, line);
        let pa = self.bg_pa[0] as i32;
        let pc = self.bg_pc[0] as i32;
        let (mut stx, mut sty) = (0i32, 0i32);
        for x in 0..SCREEN_W {
            if x as i32 % mos_h == 0 { stx = cx >> 8; sty = cy >> 8; }
            cx = cx.wrapping_add(pa);
            cy = cy.wrapping_add(pc);
            if stx < 0 || sty < 0 || stx >= 160 || sty >= 128 { continue; }
            let addr = frame_sel + (sty as usize * 160 + stx as usize) * 2;
            let color = self.vram16(addr) & 0x7FFF;
            self.line_bg[2][x] = color;
            self.bg_drawn[2][x] = true;
        }
    }

    fn render_objects(&mut self, line: u32) {
        // OBJ tile data base: 0x10000 in VRAM. 1D or 2D mapping.
        let one_dim = self.dispcnt & 0x40 != 0;
        let bitmap_mode = (self.dispcnt & 0x7) >= 3;
        let tile_base = 0x10000usize;

        // Per-scanline OBJ rendering cycle budget. Sprites are processed in OAM
        // order; once the budget is exhausted the remaining sprites are dropped.
        // 1210 cycles normally, 954 when HBlank-interval-free (DISPCNT bit 5).
        let mut obj_budget: i32 = if self.dispcnt & 0x20 != 0 { 954 } else { 1210 };

        for i in 0..128 {
            let oam_off = i * 8;
            let attr0 = u16::from_le_bytes([self.oam[oam_off], self.oam[oam_off + 1]]);
            let attr1 = u16::from_le_bytes([self.oam[oam_off + 2], self.oam[oam_off + 3]]);
            let attr2 = u16::from_le_bytes([self.oam[oam_off + 4], self.oam[oam_off + 5]]);

            let obj_mode = (attr0 >> 8) & 0x3; // 0 normal,1 affine,2 disable,3 affine double
            if obj_mode == 2 { continue; }
            let affine = obj_mode == 1 || obj_mode == 3;
            let double = obj_mode == 3;

            let gfx_mode = (attr0 >> 10) & 0x3; // 0 normal,1 semi,2 window,3 forbidden
            let mosaic = attr0 & 0x1000 != 0;
            let (mos_h, mos_v) = if mosaic {
                (((self.mosaic >> 8) & 0xF) as i32 + 1, ((self.mosaic >> 12) & 0xF) as i32 + 1)
            } else {
                (1, 1)
            };
            let color256 = attr0 & 0x2000 != 0;
            let shape = (attr0 >> 14) & 0x3;
            let size = (attr1 >> 14) & 0x3;

            let (w, h) = obj_size(shape, size);
            let (bw, bh) = if double { (w * 2, h * 2) } else { (w, h) };

            let mut y = (attr0 & 0xFF) as i32;
            if y >= 160 { y -= 256; }
            let mut x = (attr1 & 0x1FF) as i32;
            if x >= 240 { x -= 512; }

            let ly = line as i32;
            if ly < y || ly >= y + bh as i32 { continue; }

            // OBJ cycle budget: each in-range sprite costs its rendered width
            // (affine: 2*width + 10). Once exhausted, drop the rest (OAM order).
            if obj_budget <= 0 { break; }
            obj_budget -= if affine { 2 * bw as i32 + 10 } else { bw as i32 };

            let priority = ((attr2 >> 10) & 0x3) as u8;
            let pal_bank = ((attr2 >> 12) & 0xF) as usize;
            let tile_idx = (attr2 & 0x3FF) as usize;

            // Affine matrix.
            let (pa, pb, pc, pd) = if affine {
                let grp = ((attr1 >> 9) & 0x1F) as usize;
                let base = grp * 32;
                let pa = i16::from_le_bytes([self.oam[base + 6], self.oam[base + 7]]) as i32;
                let pb = i16::from_le_bytes([self.oam[base + 14], self.oam[base + 15]]) as i32;
                let pc = i16::from_le_bytes([self.oam[base + 22], self.oam[base + 23]]) as i32;
                let pd = i16::from_le_bytes([self.oam[base + 30], self.oam[base + 31]]) as i32;
                (pa, pb, pc, pd)
            } else {
                (0x100, 0, 0, 0x100)
            };

            let hflip = !affine && attr1 & 0x1000 != 0;
            let vflip = !affine && attr1 & 0x2000 != 0;

            // OBJ mosaic samples at mosaic-block-aligned screen coordinates.
            let mline = if mos_v > 1 { ly - (ly % mos_v) } else { ly };
            let iy = mline - y; // 0..bh
            let half_w = bw as i32 / 2;
            let half_h = bh as i32 / 2;

            for ix in 0..bw as i32 {
                let screen_x = x + ix;
                if screen_x < 0 || screen_x >= SCREEN_W as i32 { continue; }

                // Mosaic-aligned sprite-local x for texture sampling.
                let ix = if mos_h > 1 { (screen_x - (screen_x % mos_h)) - x } else { ix };

                // Map to texture coordinates.
                let (tex_x, tex_y);
                if affine {
                    let dx = ix - half_w;
                    let dy = iy - half_h;
                    let px = (pa * dx + pb * dy) >> 8;
                    let py = (pc * dx + pd * dy) >> 8;
                    let sx = px + w as i32 / 2;
                    let sy = py + h as i32 / 2;
                    if sx < 0 || sy < 0 || sx >= w as i32 || sy >= h as i32 { continue; }
                    tex_x = sx;
                    tex_y = sy;
                } else {
                    let mut sx = ix;
                    let mut sy = iy;
                    if hflip { sx = w as i32 - 1 - sx; }
                    if vflip { sy = h as i32 - 1 - sy; }
                    tex_x = sx;
                    tex_y = sy;
                }

                // Fetch pixel.
                let tile_w = w / 8;
                let tx = (tex_x / 8) as usize;
                let ty = (tex_y / 8) as usize;
                let in_x = (tex_x % 8) as usize;
                let in_y = (tex_y % 8) as usize;

                let color;
                if color256 {
                    // 1D: tiles are consecutive, row pitch = tile_w doubled for
                    // 8bpp (each tile = 2 slots). 2D: the grid is 32 4bpp-slots
                    // wide regardless of depth (NOT doubled); only the column
                    // step doubles for 8bpp.
                    let tile_pitch = if one_dim { tile_w as usize * 2 } else { 32 };
                    let tn = tile_idx + ty * tile_pitch + tx * 2;
                    // For bitmap modes, obj tiles must be >= 512.
                    if bitmap_mode && tile_idx < 512 { continue; }
                    let addr = tile_base + tn * 32 + (in_y * 8 + in_x);
                    if addr >= self.vram.len() { continue; }
                    let idx = self.vram[addr] as usize;
                    if idx == 0 { continue; }
                    color = self.pal16(256 + idx);
                } else {
                    let tile_pitch = if one_dim { tile_w as usize } else { 32 };
                    let tn = tile_idx + ty * tile_pitch + tx;
                    if bitmap_mode && tile_idx < 512 { continue; }
                    let addr = tile_base + tn * 32 + (in_y * 4 + in_x / 2);
                    if addr >= self.vram.len() { continue; }
                    let byte = self.vram[addr];
                    let idx = if in_x & 1 == 0 { byte & 0xF } else { byte >> 4 } as usize;
                    if idx == 0 { continue; }
                    color = self.pal16(256 + pal_bank * 16 + idx);
                }

                let sxu = screen_x as usize;
                if gfx_mode == 2 {
                    // OBJ window: mark, don't draw.
                    self.obj_window[sxu] = true;
                    continue;
                }
                // Priority: lower wins; for equal, lower OAM index wins (we iterate
                // 0..128 so first drawn wins — but later lower-priority should override).
                if !self.obj_drawn[sxu] || priority < self.obj_prio[sxu] {
                    self.obj_color[sxu] = color;
                    self.obj_prio[sxu] = priority;
                    self.obj_semi[sxu] = gfx_mode == 1;
                    self.obj_drawn[sxu] = true;
                }
            }
        }
    }

    /// Compose all layers into the framebuffer for this line, applying windows
    /// and blending.
    fn compose(&mut self, line: u32, _mode: u32) {
        let off = (line as usize) * SCREEN_W;
        let backdrop = self.pal16(0);

        let win_enabled = self.dispcnt & 0xE000 != 0;
        let win0_on = self.dispcnt & 0x2000 != 0;
        let win1_on = self.dispcnt & 0x4000 != 0;
        let winobj_on = self.dispcnt & 0x8000 != 0;

        // Window vertical ranges.
        let in_win_v = |win: usize, line: u32| -> bool {
            let v = self.winv[win];
            let y1 = (v >> 8) & 0xFF;
            let y2 = v & 0xFF;
            if y1 <= y2 {
                (line as u16) >= y1 && (line as u16) < y2
            } else {
                (line as u16) >= y1 || (line as u16) < y2
            }
        };
        let win0_v = win0_on && in_win_v(0, line);
        let win1_v = win1_on && in_win_v(1, line);

        for x in 0..SCREEN_W {
            // Determine which window applies and the layer-enable mask.
            let enable_mask: u8; // bits 0-3 bg, 4 obj, 5 effects
            if win_enabled {
                let in_win0 = win0_v && in_win_h(self.winh[0], x);
                let in_win1 = win1_v && in_win_h(self.winh[1], x);
                let in_winobj = winobj_on && self.obj_window[x];
                if in_win0 {
                    enable_mask = (self.winin & 0xFF) as u8;
                } else if in_win1 {
                    enable_mask = ((self.winin >> 8) & 0xFF) as u8;
                } else if in_winobj {
                    enable_mask = ((self.winout >> 8) & 0xFF) as u8;
                } else {
                    enable_mask = (self.winout & 0xFF) as u8;
                }
            } else {
                enable_mask = 0x3F;
            }
            let enable_mask = enable_mask & (self.debug_layer_mask as u8 | 0xE0);

            // Find top two layers by priority.
            // Layers: bg0..3 with their priority; obj.
            let mut top_color = backdrop;
            let mut top_layer = 5usize; // 5 = backdrop
            let mut top_prio = 4u8;
            let mut second_color = backdrop;
            let mut second_layer = 5usize;
            let mut second_prio = 5u8;

            // Iterate priorities 0..3, then within each, bg order then obj.
            // We need correct ordering: obj at priority p draws above bg of same p.
            // Standard: for each priority level, obj first then bg0..bg3.
            // Collect candidates.
            // First objects.
            for prio in 0..4u8 {
                // object at this priority
                if self.obj_drawn[x] && (enable_mask & 0x10 != 0) && self.obj_prio[x] == prio {
                    push_layer(self.obj_color[x], 4, prio, &mut top_color, &mut top_layer, &mut top_prio,
                        &mut second_color, &mut second_layer, &mut second_prio);
                }
                for bg in 0..4 {
                    if self.bg_drawn[bg][x]
                        && (enable_mask & (1 << bg) != 0)
                        && (self.bgcnt[bg] & 0x3) as u8 == prio
                    {
                        push_layer(self.line_bg[bg][x], bg, prio, &mut top_color, &mut top_layer, &mut top_prio,
                            &mut second_color, &mut second_layer, &mut second_prio);
                    }
                }
            }
            let _ = second_layer;

            // Blending.
            let effects_enabled = enable_mask & 0x20 != 0;
            let bld_mode = (self.bldcnt >> 6) & 0x3;
            let top_is_target1 = self.bldcnt & (1 << top_layer_bldbit(top_layer)) != 0;
            let second_is_target2 = self.bldcnt & (1 << (8 + top_layer_bldbit(second_layer))) != 0;

            let mut final_color = top_color;

            // Semi-transparent obj forces alpha blend if second is target2.
            let obj_semi = top_layer == 4 && self.obj_semi[x];

            if effects_enabled && obj_semi && second_is_target2 {
                final_color = blend_alpha(top_color, second_color, self.bldalpha);
            } else if effects_enabled && bld_mode == 1 && top_is_target1 && second_is_target2 {
                final_color = blend_alpha(top_color, second_color, self.bldalpha);
            } else if effects_enabled && bld_mode == 2 && top_is_target1 {
                final_color = blend_brighten(top_color, self.bldy);
            } else if effects_enabled && bld_mode == 3 && top_is_target1 {
                final_color = blend_darken(top_color, self.bldy);
            }

            self.frame[off + x] = Self::to_rgba(final_color);
        }

        // Green Swap (GREENSWAP reg bit 0): exchange the green component of each
        // pair of horizontally-adjacent pixels.
        if self.green_swap & 1 != 0 {
            let mut x = 0;
            while x + 1 < SCREEN_W {
                let a = self.frame[off + x];
                let b = self.frame[off + x + 1];
                let ga = a & 0x0000_FF00;
                let gb = b & 0x0000_FF00;
                self.frame[off + x] = (a & !0x0000_FF00) | gb;
                self.frame[off + x + 1] = (b & !0x0000_FF00) | ga;
                x += 2;
            }
        }
    }
}

#[inline]
fn top_layer_bldbit(layer: usize) -> u32 {
    // BLDCNT target bits: 0-3 bg0-3, 4 obj, 5 backdrop
    match layer {
        0..=3 => layer as u32,
        4 => 4,
        _ => 5,
    }
}

#[allow(clippy::too_many_arguments)]
#[inline]
fn push_layer(color: u16, layer: usize, prio: u8,
    top_color: &mut u16, top_layer: &mut usize, top_prio: &mut u8,
    second_color: &mut u16, second_layer: &mut usize, second_prio: &mut u8) {
    // Since we iterate from highest priority (0) to lowest and obj-before-bg,
    // the first pushed is the topmost. We only set top once (when still backdrop).
    if *top_layer == 5 {
        *top_color = color;
        *top_layer = layer;
        *top_prio = prio;
    } else if *second_layer == 5 {
        *second_color = color;
        *second_layer = layer;
        *second_prio = prio;
    }
}

#[inline]
fn in_win_h(winh: u16, x: usize) -> bool {
    let x1 = ((winh >> 8) & 0xFF) as usize;
    let x2 = (winh & 0xFF) as usize;
    if x1 <= x2 {
        x >= x1 && x < x2
    } else {
        x >= x1 || x < x2
    }
}

fn obj_size(shape: u16, size: u16) -> (u32, u32) {
    match (shape, size) {
        (0, 0) => (8, 8),
        (0, 1) => (16, 16),
        (0, 2) => (32, 32),
        (0, 3) => (64, 64),
        (1, 0) => (16, 8),
        (1, 1) => (32, 8),
        (1, 2) => (32, 16),
        (1, 3) => (64, 32),
        (2, 0) => (8, 16),
        (2, 1) => (8, 32),
        (2, 2) => (16, 32),
        (2, 3) => (32, 64),
        _ => (8, 8),
    }
}

#[inline]
fn blend_alpha(top: u16, bottom: u16, bldalpha: u16) -> u16 {
    let eva = (bldalpha & 0x1F).min(16) as u32;
    let evb = ((bldalpha >> 8) & 0x1F).min(16) as u32;
    let blend = |t: u32, b: u32| -> u32 {
        ((t * eva + b * evb) >> 4).min(31)
    };
    let r = blend((top & 0x1F) as u32, (bottom & 0x1F) as u32);
    let g = blend(((top >> 5) & 0x1F) as u32, ((bottom >> 5) & 0x1F) as u32);
    let b = blend(((top >> 10) & 0x1F) as u32, ((bottom >> 10) & 0x1F) as u32);
    (r | (g << 5) | (b << 10)) as u16
}

#[inline]
fn blend_brighten(top: u16, bldy: u16) -> u16 {
    let evy = (bldy & 0x1F).min(16) as u32;
    let up = |c: u32| -> u32 { c + (((31 - c) * evy) >> 4) };
    let r = up((top & 0x1F) as u32);
    let g = up(((top >> 5) & 0x1F) as u32);
    let b = up(((top >> 10) & 0x1F) as u32);
    (r | (g << 5) | (b << 10)) as u16
}

#[inline]
fn blend_darken(top: u16, bldy: u16) -> u16 {
    let evy = (bldy & 0x1F).min(16) as u32;
    // Hardware floors the whole darkened value: I*(16-EVY)/16, which equals
    // I - ceil(I*EVY/16). Subtracting the floored decrement (I - (I*EVY>>4))
    // rounds the wrong way for fractional results.
    let down = |c: u32| -> u32 { (c * (16 - evy)) >> 4 };
    let r = down((top & 0x1F) as u32);
    let g = down(((top >> 5) & 0x1F) as u32);
    let b = down(((top >> 10) & 0x1F) as u32);
    (r | (g << 5) | (b << 10)) as u16
}
