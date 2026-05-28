//! Four hardware timers.

#[derive(Clone, Copy, Default)]
pub struct Timer {
    pub counter: u16,   // current value
    pub reload: u16,    // TMxCNT_L reload value
    pub control: u16,   // TMxCNT_H
    pub prescaler_cycles: u32, // accumulated cycles toward next tick
}

impl Timer {
    pub fn prescaler_shift(&self) -> u32 {
        match self.control & 0x3 {
            0 => 0,   // 1
            1 => 6,   // 64
            2 => 8,   // 256
            3 => 10,  // 1024
            _ => 0,
        }
    }
    pub fn enabled(&self) -> bool {
        self.control & 0x80 != 0
    }
    pub fn cascade(&self) -> bool {
        self.control & 0x4 != 0
    }
    pub fn irq(&self) -> bool {
        self.control & 0x40 != 0
    }
}

#[derive(Clone)]
pub struct Timers {
    pub t: [Timer; 4],
}

impl Timers {
    pub fn new() -> Self {
        Timers { t: [Timer::default(); 4] }
    }
}
