const std = @import("std");
const ray = @cImport(@cInclude("raylib.h"));
const li = @import("backend.zig");
const stdout = std.io.getStdOut().writer();

const SCALE: u32 = 15;
const WINDOW_WIDTH: u32 = li.SCREEN_WIDTH * SCALE;
const WINDOW_HEIGHT: u32 = li.SCREEN_HEIGHT * SCALE;
const TICKS_PER_FRAME: usize = 10;

fn drawScreen(emu: *li.Emu) void {
    const screen_buf = emu.getDisplay();

    for (screen_buf, 0..) |pixel, i| {
        if (pixel) {
            const x = (i % li.SCREEN_WIDTH);
            const y = (i / li.SCREEN_WIDTH);
            ray.DrawRectangle(@intCast(x * SCALE), @intCast(y * SCALE), @intCast(SCALE), @intCast(SCALE), ray.WHITE);
        }
    }
}

pub fn main() !void {
    var arg_iter = try std.process.ArgIterator.initWithAllocator(std.heap.page_allocator);
    defer arg_iter.deinit();

    var count: usize = 0;
    var args: [2][]const u8 = undefined;

    while (arg_iter.next()) |arg| : (count += 1) {
        if (count >= 2) {
            try std.io.getStdErr().writer().print("To many arguments\nUsage: li8z path/to/game\n", .{});
            return;
        }
        args[count] = arg;
    }

    var chip = li.Emu.init();
    var buffer = std.ArrayList(u8).init(std.heap.page_allocator);
    defer buffer.deinit();

    const rom = std.fs.cwd().openFile(args[1], .{}) catch |err| {
        std.debug.print("Unable to open file: {}\n", .{err});
        return;
    };
    defer rom.close();

    const data = rom.readToEndAlloc(buffer.allocator, 4096) catch |err| {
        std.debug.print("Unable to read file: {}\n", .{err});
        return;
    };

    try buffer.appendSlice(data);

    chip.load(&buffer.items);

    ray.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Li8z");
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        defer ray.EndDrawing();

        for (0..TICKS_PER_FRAME) |_| {
            chip.tick();
        }

        chip.tickTimers();
        drawScreen(&chip);

        ray.ClearBackground(ray.BLACK);
    }
}
