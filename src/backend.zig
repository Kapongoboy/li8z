pub const SCREEN_WIDTH: usize = 64;
pub const SCREEN_HEIGHT: usize = 32;

const RAM_SIZE: usize = 4096;
const NUM_REGS: usize = 16;
const STACK_SIZE: usize = 16;
const NUM_KEYS: usize = 16;
const FONTSET_SIZE: usize = 80;
const FONTSET = [FONTSET_SIZE]u8{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
};

pub const Emu = struct {
    const START_ADDR: u16 = 0x200;
    pc: u16,
    ram: [RAM_SIZE]u8,
    screen: [SCREEN_WIDTH * SCREEN_HEIGHT]bool,
    v_reg: [NUM_REGS]u8,
    i_reg: u16,
    sp: u16,
    stack: [STACK_SIZE]u16,
    keys: [NUM_KEYS]bool,
    dt: u8,
    st: u8,

    pub fn init() Emu {
        var new_emu = Emu{
            .pc = START_ADDR,
            .ram = undefined,
            .screen = undefined,
            .v_reg = undefined,
            .i_reg = 0,
            .sp = 0,
            .stack = undefined,
            .keys = undefined,
            .dt = 0,
            .st = 0,
        };

        const ram_slice = new_emu.ram[0..80];
        ram_slice.* = FONTSET;
        return new_emu;
    }

    fn push(self: *Emu, val: u16) void {
        self.stack[@intCast(self.sp)] = val;
        self.sp += 1;
    }

    fn pop(self: *Emu) u16 {
        self.sp -= 1;
        return self.stack[@intCast(self.sp)];
    }

    pub fn reset(self: *Emu) void {
        self.pc = Emu.START_ADDR;
        self.i_reg = 0;
        self.sp = 0;
        self.dt = 0;
        self.st = 0;
        self.screen = undefined;
        self.v_reg = undefined;
        self.stack = undefined;
        self.keys = undefined;
        self.ram = undefined;
        const ram_slice = self.ram[0..80];
        ram_slice.* = FONTSET;
    }

    pub fn tick(self: *Emu) void {
        const op = self.fetch();
        self.execute(op);
    }

    fn execute(self: *Emu, op: u16) void {
        // TODO
    }

    fn fetch(self: *Emu) u16 {
        const higher_byte: u16 = self.ram[@intCast(self.pc)];
        const lower_byte: u16 = self.ram[@intCast(self.pc + 1)];
        const op = (higher_byte << 8) | lower_byte;
        self.pc += 2;
        return op;
    }

    pub fn tick_timers(self: *Emu) void {
        if (self.dt > 0) self.dt -= 1;

        if (self.st > 0) {
            if (self.st == 1) {
                // GONNA BEEP HERE
            }
            self.st -= 1;
        }
    }
};

test "Undefined arrays correct" {
    const std = @import("std");

    const emu = Emu.init();

    try std.testing.expectEqual(512, emu.pc);

    for (emu.screen) |i| {
        try std.testing.expectEqual(false, i);
    }

    for (emu.v_reg) |i| {
        try std.testing.expectEqual(0, i);
    }

    for (emu.stack) |i| {
        try std.testing.expectEqual(0, i);
    }

    for (emu.keys) |i| {
        try std.testing.expectEqual(false, i);
    }
}

test "FONTSET slice write" {
    const std = @import("std");

    const emu = Emu.init();

    try std.testing.expectEqual(FONTSET, emu.ram[0..80].*);
}
