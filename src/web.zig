const std = @import("std");
const backend = @import("backend.zig");

// Expose key emulator functions to JavaScript
export fn initEmulator() *backend.Emu {
    var emu = backend.Emu.init();
    return &emu;
}

export fn tickEmulator(emu: *backend.Emu) void {
    emu.tick();
}

export fn tickTimers(emu: *backend.Emu) bool {
    return emu.tickTimers();
}

export fn keyPress(emu: *backend.Emu, key: usize, pressed: bool) void {
    emu.keypress(key, pressed);
}

export fn getScreenPtr(emu: *backend.Emu) [*]bool {
    return emu.getDisplay().ptr;
}

export fn loadROM(emu: *backend.Emu, ptr: [*]const u8, len: usize) void {
    var data = ptr[0..len];
    emu.load(&data);
}

export fn resetEmulator(emu: *backend.Emu) void {
    emu.reset();
}

export fn getScreenWidth() usize {
    return backend.SCREEN_WIDTH;
}

export fn getScreenHeight() usize {
    return backend.SCREEN_HEIGHT;
}

export fn setSeed(seed: u64) void {
    backend.prng.seed(seed);
}
