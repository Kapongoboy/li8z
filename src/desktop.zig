const std = @import("std");
const ray = @cImport(@cInclude("raylib.h"));
const li = @import("backend.zig");

const SCALE: u32 = 15;
const WINDOW_WIDTH: u32 = li.SCREEN_WIDTH * SCALE;
const WINDOW_HEIGHT: u32 = li.SCREEN_HEIGHT * SCALE;

pub fn main() !void {
    var arg_iter = try std.process.ArgIterator.initWithAllocator(std.heap.page_allocator);
    defer arg_iter.deinit();

    var count: usize = 0;
    var args: [2][]const u8 = undefined;

    while (arg_iter.next()) |arg| : (count += 1) {
        if (count > 2) {
            try std.io.getStdErr().writer().print("To many arguments\nUsage: li8z path/to/game\n", .{});
            return;
        }
        args[count] = arg;
    }

    ray.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Li8z");
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        defer ray.EndDrawing();

        ray.ClearBackground(ray.RAYWHITE);
        ray.DrawText("Li8z", 190, 200, 20, ray.MAROON);
    }
}
