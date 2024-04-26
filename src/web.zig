const li = @import("backend.zig");

export const EmuWasm = struct {
    chip8: li.Emu,

    extern fn initEmu() EmuWasm;

    pub fn tick(self: *EmuWasm) void {
        self.chip8.tick();
    }

    pub fn tickTimers(self: *EmuWasm) bool {
        return self.chip8.tickTimers();
    }

    pub fn reset(self: *EmuWasm) void {
        self.chip8.reset();
    }

    pub fn keypress(self: *EmuWasm, key: []const u8, pressed: bool) void {
        const btn = key2btn(key);
        if (btn) |b| {
            self.chip8.keypress(b, pressed);
        }
    }

    pub fn loadGame(self: *EmuWasm, data: []u8) void {
        self.chip8.load(&data);
    }

    pub fn drawScreen(self: *Self, scale: usize) void {}
};

fn key2btn(key: []const u8) ?usize {
    switch (key[0]) {
        0x1 => return 0,
        0x2 => return 1,
        0x3 => return 2,
        0xC => return 3,
        0x4 => return 4,
        0x5 => return 5,
        0x6 => return 6,
        0xD => return 7,
        0x7 => return 8,
        0x8 => return 9,
        0x9 => return 10,
        0xE => return 11,
        0xA => return 12,
        0x0 => return 13,
        0xB => return 14,
        0xF => return 15,
        else => return null,
    }
}
