const std = @import("std");
const random = std.crypto.random;

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

    pub fn getDisplay(self: *Emu) []bool {
        return &self.screen;
    }

    pub fn keypress(self: *Emu, idx: usize, pressed: bool) void {
        self.keys[idx] = pressed;
    }

    pub fn load(self: *Emu, data: *[]u8) void {
        const start: usize = @intCast(START_ADDR);
        const end: usize = start + data.len;

        for (start..end) |i| {
            self.ram[i] = data.*[i - start];
        }
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
        const digit1 = (op & 0xF000) >> 12;
        const digit2 = (op & 0x0F00) >> 8;
        const digit3 = (op & 0x00F0) >> 4;
        const digit4 = (op & 0x000F);

        if ((digit1 == 0) and (digit2 == 0) and (digit3 == 0) and (digit4 == 0)) return;

        if ((digit1 == 0) and (digit2 == 0) and (digit3 == 0xE) and (digit4 == 0)) {
            self.screen = undefined;
        } else if ((digit1 == 0) and (digit2 == 0) and (digit3 == 0xE) and (digit4 == 0xE)) {
            const ret_addr = self.pop();
            self.pc = ret_addr;
        } else if ((digit1 == 1)) {
            const nnn = op & 0xFFF;
            self.pc = nnn;
        } else if ((digit1 == 2)) {
            const nnn = op & 0xFFF;
            self.push(self.pc);
            self.pc = nnn;
        } else if ((digit1 == 3)) {
            const x = digit2;
            const nn = op & 0xFF;
            if (self.v_reg[@intCast(x)] == nn) {
                self.pc += 2;
            }
        } else if ((digit1 == 4)) {
            const x = digit2;
            const nn = op & 0xFF;
            if (self.v_reg[@intCast(x)] != nn) {
                self.pc += 2;
            }
        } else if ((digit1 == 5) and (digit4 == 0)) {
            const x = digit2;
            const y = digit3;
            if (self.v_reg[@intCast(x)] == self.v_reg[@intCast(y)]) {
                self.pc += 2;
            }
        } else if ((digit1 == 6)) {
            const x = digit2;
            const nn = op & 0xFF;
            self.v_reg[@intCast(x)] = @intCast(nn);
        } else if ((digit1 == 7)) {
            const x: usize = @intCast(digit2);
            const nn = op & 0xFF;
            const nn_u8: u8 = @intCast(nn);
            self.v_reg[x] = @addWithOverflow(self.v_reg[x], nn_u8)[0];
        } else if ((digit1 == 8) and (digit4 == 0)) {
            const x = digit2;
            const y = digit3;
            self.v_reg[@intCast(x)] = self.v_reg[@intCast(y)];
        } else if ((digit1 == 8) and (digit4 == 1)) {
            const x = digit2;
            const y = digit3;
            self.v_reg[@intCast(x)] |= self.v_reg[@intCast(y)];
        } else if ((digit1 == 8) and (digit4 == 2)) {
            const x = digit2;
            const y = digit3;
            self.v_reg[@intCast(x)] &= self.v_reg[@intCast(y)];
        } else if ((digit1 == 8) and (digit4 == 3)) {
            const x = digit2;
            const y = digit3;
            self.v_reg[@intCast(x)] ^= self.v_reg[@intCast(y)];
        } else if ((digit1 == 8) and (digit4 == 4)) {
            const x = digit2;
            const y = digit3;
            const result = @addWithOverflow(self.v_reg[@intCast(x)], self.v_reg[@intCast(y)]);
            self.v_reg[@intCast(x)] = result[0];
            self.v_reg[0xF] = result[1];
        } else if ((digit1 == 8) and (digit4 == 5)) {
            const x = digit2;
            const y = digit3;
            const result = @subWithOverflow(self.v_reg[@intCast(x)], self.v_reg[@intCast(y)]);
            self.v_reg[@intCast(x)] = result[0];
            self.v_reg[0xF] = if (result[1] == 1) 0 else 1;
        } else if ((digit1 == 8) and (digit4 == 6)) {
            const x = digit2;
            self.v_reg[0xF] = self.v_reg[@intCast(x)] & 0x1;
            self.v_reg[@intCast(x)] >>= 1;
        } else if ((digit1 == 8) and (digit4 == 7)) {
            const x = digit2;
            const y = digit3;
            const result = @subWithOverflow(self.v_reg[@intCast(y)], self.v_reg[@intCast(x)]);
            self.v_reg[@intCast(x)] = result[0];
            self.v_reg[0xF] = if (result[1] == 1) 0 else 1;
        } else if ((digit1 == 8) and (digit4 == 0xE)) {
            const x = digit2;
            self.v_reg[0xF] = (self.v_reg[@intCast(x)] >> 7) & 0x1;
            self.v_reg[@intCast(x)] <<= 1;
        } else if ((digit1 == 9) and (digit4 == 0)) {
            const x = digit2;
            const y = digit3;
            if (self.v_reg[@intCast(x)] != self.v_reg[@intCast(y)]) {
                self.pc += 2;
            }
        } else if (digit1 == 0xA) {
            const nnn = op & 0xFFF;
            self.i_reg = nnn;
        } else if (digit1 == 0xB) {
            const nnn = op & 0xFFF;
            self.pc = nnn + self.v_reg[0];
        } else if (digit1 == 0xC) {
            const x = digit2;
            const nn = op & 0xFF;
            const nn_u8: u8 = @intCast(nn);
            self.v_reg[@intCast(x)] = random.int(u8) & nn_u8;
        } else if (digit1 == 0xD) {
            const x_coord = self.v_reg[@intCast(digit2)];
            const y_coord = self.v_reg[@intCast(digit3)];
            const num_rows = digit4;
            var flipped = false;

            for (0..num_rows) |y_line| {
                const addr = self.i_reg + y_line;
                const pixels = self.ram[@intCast(addr)];

                for (0..8) |x_line| {
                    const x_line_trunc: u4 = @intCast(x_line);
                    if ((pixels & (@as(u16, 0b1000_0000) >> x_line_trunc)) != 0) {
                        const x = (x_coord + x_line) % SCREEN_WIDTH;
                        const y = (y_coord + y_line) % SCREEN_HEIGHT;
                        const idx = x + SCREEN_WIDTH * y;
                        flipped = flipped or self.screen[idx];
                        self.screen[idx] = self.screen[idx] != true;
                    }
                }
            }

            if (flipped) {
                self.v_reg[0xF] = 1;
            } else {
                self.v_reg[0xF] = 0;
            }
        } else if ((digit1 == 0xE) and (digit3 == 9) and (digit4 == 0xE)) {
            const x: usize = @intCast(digit2);
            const vx = self.v_reg[x];
            const key = self.keys[@intCast(vx)];
            if (key) {
                self.pc += 2;
            }
        } else if ((digit1 == 0xE) and (digit3 == 0xA) and (digit4 == 1)) {
            const x: usize = @intCast(digit2);
            const vx = self.v_reg[x];
            const key = self.keys[@intCast(vx)];
            if (!key) {
                self.pc += 2;
            }
        } else if ((digit1 == 0xF) and (digit3 == 0) and (digit4 == 7)) {
            const x: usize = @intCast(digit2);
            self.v_reg[x] = self.dt;
        } else if ((digit1 == 0xF) and (digit3 == 0) and (digit4 == 0xA)) {
            const x: usize = @intCast(digit2);
            var pressed = false;
            for (0..self.keys.len) |i| {
                if (self.keys[i]) {
                    self.v_reg[x] = @intCast(i);
                    pressed = true;
                    break;
                }
            }

            if (!pressed) {
                self.pc -= 2;
            }
        } else if ((digit1 == 0xF) and (digit3 == 1) and (digit4 == 8)) {
            const x: usize = @intCast(digit2);
            self.st = self.v_reg[x];
        } else if ((digit1 == 0xF) and (digit3 == 1) and (digit4 == 0xE)) {
            const x: usize = @intCast(digit2);
            const vx = self.v_reg[x];
            self.i_reg = @addWithOverflow(self.i_reg, vx)[0];
        } else if ((digit1 == 0xF) and (digit3 == 2) and (digit4 == 9)) {
            const x: usize = @intCast(digit2);
            const c = self.v_reg[x];
            self.i_reg = c * 5;
        } else if ((digit1 == 0xF) and (digit3 == 3) and (digit4 == 3)) {
            const x: usize = @intCast(digit2);
            const vx: f32 = @floatFromInt(self.v_reg[x]);

            const hundreds: u8 = @intFromFloat(@rem(vx, 100.0));
            const tens: u8 = @intFromFloat(@rem(@rem(vx, 10.0), 10.0));
            const ones: u8 = @intFromFloat(@rem(vx, 10.0));

            self.ram[@intCast(self.i_reg)] = hundreds;
            self.ram[@intCast(self.i_reg + 1)] = tens;
            self.ram[@intCast(self.i_reg + 2)] = ones;
        } else if ((digit1 == 0xF) and (digit3 == 5) and (digit4 == 5)) {
            const x: usize = @intCast(digit2);
            const i: usize = @intCast(self.i_reg);
            for (0..x + 1) |idx| {
                self.ram[i + idx] = self.v_reg[idx];
            }
        } else if ((digit1 == 0xF) and (digit3 == 6) and (digit4 == 5)) {
            const x: usize = @intCast(digit2);
            const i: usize = @intCast(self.i_reg);
            for (0..x + 1) |idx| {
                self.v_reg[idx] = self.ram[i + idx];
            }
        }

        return;
    }

    fn fetch(self: *Emu) u16 {
        const higher_byte: u16 = self.ram[@intCast(self.pc)];
        const lower_byte: u16 = self.ram[@intCast(self.pc + 1)];
        const op = (higher_byte << 8) | lower_byte;
        self.pc += 2;
        return op;
    }

    pub fn tickTimers(self: *Emu) void {
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
    const emu = Emu.init();

    try std.testing.expectEqual(FONTSET, emu.ram[0..80].*);
}
