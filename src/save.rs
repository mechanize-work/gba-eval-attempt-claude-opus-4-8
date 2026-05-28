//! Cartridge backup memory: SRAM, Flash (64K/128K), EEPROM (512B/8K).

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum SaveType {
    None,
    Sram,        // 32 KiB
    Flash64,     // 64 KiB
    Flash128,    // 128 KiB (2 banks)
    Eeprom512,   // 512 bytes (6-bit address)
    Eeprom8k,    // 8 KiB (14-bit address)
}

/// Detect the save type by scanning the ROM for the standard signature strings.
pub fn detect(rom: &[u8]) -> SaveType {
    fn find(rom: &[u8], pat: &[u8]) -> bool {
        rom.windows(pat.len()).any(|w| w == pat)
    }
    if find(rom, b"FLASH1M_V") || find(rom, b"FLASH1M") {
        SaveType::Flash128
    } else if find(rom, b"FLASH512_V") || find(rom, b"FLASH_V") || find(rom, b"FLASH") {
        SaveType::Flash64
    } else if find(rom, b"EEPROM_V") || find(rom, b"EEPROM") {
        // Size determined later by access width; default to 8k.
        SaveType::Eeprom8k
    } else if find(rom, b"SRAM_V") || find(rom, b"SRAM") {
        SaveType::Sram
    } else {
        SaveType::Sram // safest default
    }
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum FlashState {
    Ready,
    Cmd1,        // got AA at 5555
    Cmd2,        // got 55 at 2AAA
    WriteByte,   // next write is data (A0)
    BankSwitch,  // next write selects bank (B0)
}

#[derive(Clone)]
pub struct Save {
    pub ty: SaveType,
    pub data: Vec<u8>,

    // Flash state.
    fstate: FlashState,
    id_mode: bool,
    erase_mode: bool,
    bank: usize,
    // Flash chip identity (Sanyo/Macronix style).
    manuf: u8,
    device: u8,

    // EEPROM serial state.
    ee_buffer: u64,
    ee_bits: u32,
    ee_addr: usize,
    ee_mode: EeMode,
    ee_read_bits: u32,
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum EeMode {
    Idle,
    ReadAddr,
    Reading,
    WriteAddr,
    WriteData,
}

impl Save {
    pub fn new(ty: SaveType) -> Self {
        let (size, manuf, device) = match ty {
            SaveType::Sram => (32 * 1024, 0, 0),
            SaveType::Flash64 => (64 * 1024, 0x32, 0x1B),   // Panasonic 64K
            SaveType::Flash128 => (128 * 1024, 0x62, 0x13), // Sanyo 128K
            SaveType::Eeprom512 => (512, 0, 0),
            SaveType::Eeprom8k => (8 * 1024, 0, 0),
            SaveType::None => (0, 0, 0),
        };
        Save {
            ty,
            data: vec![0xFFu8; size],
            fstate: FlashState::Ready,
            id_mode: false,
            erase_mode: false,
            bank: 0,
            manuf,
            device,
            ee_buffer: 0,
            ee_bits: 0,
            ee_addr: 0,
            ee_mode: EeMode::Idle,
            ee_read_bits: 0,
        }
    }

    pub fn is_eeprom(&self) -> bool {
        matches!(self.ty, SaveType::Eeprom512 | SaveType::Eeprom8k)
    }

    // --- SRAM / Flash region (0x0E000000) --------------------------------
    pub fn read8(&self, addr: u32) -> u8 {
        let off = (addr & 0xFFFF) as usize;
        match self.ty {
            SaveType::Sram => {
                self.data.get(off).copied().unwrap_or(0xFF)
            }
            SaveType::Flash64 | SaveType::Flash128 => {
                if self.id_mode {
                    match off {
                        0 => self.manuf,
                        1 => self.device,
                        _ => 0xFF,
                    }
                } else {
                    let idx = self.bank * 0x10000 + off;
                    self.data.get(idx).copied().unwrap_or(0xFF)
                }
            }
            _ => 0xFF,
        }
    }

    pub fn write8(&mut self, addr: u32, val: u8) {
        let off = (addr & 0xFFFF) as usize;
        match self.ty {
            SaveType::Sram => {
                if off < self.data.len() {
                    self.data[off] = val;
                }
            }
            SaveType::Flash64 | SaveType::Flash128 => self.flash_write(off, val),
            _ => {}
        }
    }

    fn flash_write(&mut self, off: usize, val: u8) {
        // Handle data/bank states first.
        match self.fstate {
            FlashState::WriteByte => {
                let idx = self.bank * 0x10000 + off;
                if idx < self.data.len() {
                    // Flash write can only clear bits (AND).
                    self.data[idx] &= val;
                }
                self.fstate = FlashState::Ready;
                return;
            }
            FlashState::BankSwitch => {
                if off == 0 {
                    self.bank = (val & 1) as usize;
                }
                self.fstate = FlashState::Ready;
                return;
            }
            _ => {}
        }

        // Command sequence at 0x5555 / 0x2AAA.
        match (self.fstate, off, val) {
            (FlashState::Ready, 0x5555, 0xAA) => self.fstate = FlashState::Cmd1,
            (FlashState::Cmd1, 0x2AAA, 0x55) => self.fstate = FlashState::Cmd2,
            (FlashState::Cmd2, 0x5555, cmd) => {
                self.fstate = FlashState::Ready;
                match cmd {
                    0x90 => self.id_mode = true,
                    0xF0 => self.id_mode = false,
                    0x80 => self.erase_mode = true,
                    0x10 => {
                        if self.erase_mode {
                            for b in self.data.iter_mut() { *b = 0xFF; }
                            self.erase_mode = false;
                        }
                    }
                    0xA0 => self.fstate = FlashState::WriteByte,
                    0xB0 => self.fstate = FlashState::BankSwitch,
                    _ => {}
                }
            }
            (FlashState::Cmd2, _, 0x30) => {
                // Sector erase (4 KiB sector at off).
                if self.erase_mode {
                    let sector = (self.bank * 0x10000) + (off & 0xF000);
                    for i in 0..0x1000 {
                        if sector + i < self.data.len() {
                            self.data[sector + i] = 0xFF;
                        }
                    }
                    self.erase_mode = false;
                }
                self.fstate = FlashState::Ready;
            }
            _ => {
                self.fstate = FlashState::Ready;
            }
        }
    }

    // --- EEPROM (accessed via DMA to 0x0D000000) -------------------------
    // The GBA streams bits via DMA. We model a simple serial protocol.
    pub fn eeprom_read_bit(&mut self) -> u8 {
        match self.ee_mode {
            EeMode::Reading => {
                // First 4 bits are dummy (0), then 64 data bits MSB-first.
                if self.ee_read_bits < 4 {
                    self.ee_read_bits += 1;
                    0
                } else {
                    let bit_index = self.ee_read_bits - 4;
                    self.ee_read_bits += 1;
                    let byte = self.ee_addr * 8 + (bit_index / 8) as usize;
                    let bit = 7 - (bit_index % 8);
                    let v = self.data.get(byte).copied().unwrap_or(0xFF);
                    if self.ee_read_bits - 4 >= 64 {
                        self.ee_mode = EeMode::Idle;
                    }
                    (v >> bit) & 1
                }
            }
            _ => 1,
        }
    }

    pub fn eeprom_write_bit(&mut self, bit: u8, addr_bits: u32) {
        self.ee_buffer = (self.ee_buffer << 1) | (bit as u64 & 1);
        self.ee_bits += 1;
        match self.ee_mode {
            EeMode::Idle => {
                if self.ee_bits == 2 {
                    let req = self.ee_buffer & 0x3;
                    self.ee_buffer = 0;
                    self.ee_bits = 0;
                    if req == 0b11 {
                        self.ee_mode = EeMode::ReadAddr;
                    } else if req == 0b10 {
                        self.ee_mode = EeMode::WriteAddr;
                    }
                }
            }
            EeMode::ReadAddr => {
                if self.ee_bits == addr_bits {
                    self.ee_addr = (self.ee_buffer & ((1 << addr_bits) - 1)) as usize;
                    self.ee_buffer = 0;
                    self.ee_bits = 0;
                    self.ee_mode = EeMode::Reading;
                    self.ee_read_bits = 0;
                }
            }
            EeMode::WriteAddr => {
                if self.ee_bits == addr_bits {
                    self.ee_addr = (self.ee_buffer & ((1u64 << addr_bits) - 1)) as usize;
                    self.ee_buffer = 0;
                    self.ee_bits = 0;
                    self.ee_mode = EeMode::WriteData;
                }
            }
            EeMode::WriteData => {
                if self.ee_bits == 64 {
                    let data = self.ee_buffer;
                    let base = self.ee_addr * 8;
                    for i in 0..8 {
                        if base + i < self.data.len() {
                            self.data[base + i] = (data >> (56 - i * 8)) as u8;
                        }
                    }
                    self.ee_buffer = 0;
                    self.ee_bits = 0;
                    self.ee_mode = EeMode::Idle;
                }
            }
            _ => {}
        }
    }
}
