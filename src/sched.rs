//! Minimal cycle counter / timing helper.

#[derive(Clone)]
pub struct Sched {
    pub now: u64,
}

impl Sched {
    pub fn new() -> Self {
        Sched { now: 0 }
    }
    #[inline]
    pub fn add(&mut self, cycles: u32) {
        self.now += cycles as u64;
    }
}
