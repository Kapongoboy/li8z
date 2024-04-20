pub const SCREEN_WIDTH: usize = 64;
pub const SCREEN_HEIGHT: usize = 32;

const RAM_SIZE: usize = 4096;
const NUM_REGS: usize = 16;
const STACK_SIZE: usize = 16;
const NUM_KEYS: usize = 16;

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
        return Emu{
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
    }
};

test "Default arrays correct" {
    const std = @import("std");

    const emu = Emu.init();

    try std.testing.expectEqual(512, emu.pc);

    for (emu.ram) |i| {
        try std.testing.expectEqual(0, i);
    }

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
