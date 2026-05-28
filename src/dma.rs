//! Four DMA channels.

#[derive(Clone, Copy, Default)]
pub struct DmaChannel {
    pub src: u32,
    pub dst: u32,
    pub count: u32,    // word count (0 = max)
    pub control: u16,  // DMAxCNT_H
    // Internal latched values used while a transfer is active.
    pub cur_src: u32,
    pub cur_dst: u32,
    pub cur_count: u32,
    pub active: bool,  // currently mid-transfer (for repeat handling)
}

impl DmaChannel {
    pub fn enabled(&self) -> bool {
        self.control & 0x8000 != 0
    }
    pub fn dst_adjust(&self) -> u32 {
        (self.control >> 5) & 0x3
    }
    pub fn src_adjust(&self) -> u32 {
        (self.control >> 7) & 0x3
    }
    pub fn repeat(&self) -> bool {
        self.control & 0x0200 != 0
    }
    pub fn word_size(&self) -> bool {
        self.control & 0x0400 != 0 // true => 32-bit
    }
    pub fn timing(&self) -> u32 {
        (self.control >> 12) & 0x3
    }
    pub fn irq(&self) -> bool {
        self.control & 0x4000 != 0
    }
}

#[derive(Clone)]
pub struct Dma {
    pub ch: [DmaChannel; 4],
}

impl Dma {
    pub fn new() -> Self {
        Dma { ch: [DmaChannel::default(); 4] }
    }
}
