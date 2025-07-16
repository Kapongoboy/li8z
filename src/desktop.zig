const std = @import("std");
const ray = @cImport({
    @cInclude("raylib.h");
    @cDefine("RAYGUI_IMPLEMENTATION", {});
    @cInclude("raygui.h");
    @cInclude("tinyfiledialogs.h");
});
const ma = @cImport({@cInclude("miniaudio.h");});
const li = @import("backend.zig");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();
const zaudio = @import("zaudio");

const MiniAudioErrors = error{
    InitFailed,
    VolumeFailed,
    PlaySoundFailed,
};

const SCALE: u32 = 15;
const WINDOW_WIDTH: u32 = li.SCREEN_WIDTH * SCALE;
const WINDOW_HEIGHT: u32 = li.SCREEN_HEIGHT * SCALE;
const TICKS_PER_FRAME: usize = 10;

const game_keys = [_]i32{
    ray.KEY_ONE,
    ray.KEY_TWO,
    ray.KEY_THREE,
    ray.KEY_FOUR,
    ray.KEY_Q,
    ray.KEY_W,
    ray.KEY_E,
    ray.KEY_R,
    ray.KEY_A,
    ray.KEY_S,
    ray.KEY_D,
    ray.KEY_F,
    ray.KEY_Z,
    ray.KEY_X,
    ray.KEY_C,
    ray.KEY_V,
};

fn key2btn(key: c_int) ?usize {
    switch (key) {
        ray.KEY_ONE => return 0,
        ray.KEY_TWO => return 1,
        ray.KEY_THREE => return 2,
        ray.KEY_FOUR => return 3,
        ray.KEY_Q => return 4,
        ray.KEY_W => return 5,
        ray.KEY_E => return 6,
        ray.KEY_R => return 7,
        ray.KEY_A => return 8,
        ray.KEY_S => return 9,
        ray.KEY_D => return 10,
        ray.KEY_F => return 11,
        ray.KEY_Z => return 12,
        ray.KEY_X => return 13,
        ray.KEY_C => return 14,
        ray.KEY_V => return 15,
        else => return null,
    }
}

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

const GameState = enum {
    menu,
    running,
};

pub fn main() !void {
    var result: ma.ma_result = undefined;
    var engine: ma.ma_engine = undefined;

    result = ma.ma_engine_init(null, &engine);
    defer ma.ma_engine_uninit(&engine);

    if (result != ma.MA_SUCCESS) {
        std.debug.print("ma_engine_init failed: {}\n", .{result});
        return MiniAudioErrors.InitFailed;
    }

    result = ma.ma_engine_set_volume(&engine, 0.1);

    if (result != ma.MA_SUCCESS) {
        std.debug.print("ma_engine_set_volume failed: {}\n", .{result});
        return MiniAudioErrors.VolumeFailed;
    }

    var game_state: GameState = .menu;
    var chip = li.Emu.init();
    var selected_file: ?[]const u8 = null;
    const filter_pattens = [_][*c]const u8{ "*.ch8", "*.rom" };

    ray.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Li8z");
    defer ray.CloseWindow();

    // Load and set window icon
    const icon = ray.LoadImage("public/li8z-icon.png");
    ray.SetWindowIcon(icon);
    ray.UnloadImage(icon);

    ray.SetTargetFPS(60);

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        defer ray.EndDrawing();
        ray.ClearBackground(ray.BLACK);

        switch (game_state) {
            .menu => {
                // Draw centered title
                const title = "Li8z CHIP-8 Emulator";
                const title_width = ray.MeasureText(title, 40);
                ray.DrawText(title, @divTrunc(@as(i32, WINDOW_WIDTH) - title_width, 2), 100, 40, ray.WHITE);

                // Draw file selection button
                const btn_width: i32 = 200;
                const btn_height: i32 = 40;
                const btn_x = @divTrunc(@as(i32, WINDOW_WIDTH) - btn_width, 2);
                const file_btn_y: i32 = 200;
                const start_btn_y: i32 = 300;

                const file_btn_rec = ray.Rectangle{ .x = @floatFromInt(btn_x), .y = file_btn_y, .width = btn_width, .height = btn_height };
                const start_btn_rec = ray.Rectangle{ .x = @floatFromInt(btn_x), .y = start_btn_y, .width = btn_width, .height = btn_height };

                if (ray.GuiButton(file_btn_rec, "Select ROM") != 0) {
                    const file_path = ray.tinyfd_openFileDialog("Select ROM file", "", 2, &filter_pattens, "chip8 roms", 0);
                    if (file_path != null) {
                        selected_file = std.mem.span(file_path);
                    }
                }

                // Display selected file
                if (selected_file) |file| {
                    const text_width = ray.MeasureText(file.ptr, 20);
                    ray.DrawText(file.ptr, @divTrunc(@as(i32, WINDOW_WIDTH) - text_width, 2), 250, 20, ray.WHITE);
                }

                // Draw start button (only enabled if file is selected)
                if (selected_file != null and ray.GuiButton(start_btn_rec, "Start Game") != 0) {
                    // Load ROM and start game
                    var buffer = std.ArrayList(u8).init(std.heap.page_allocator);
                    defer buffer.deinit();

                    if (std.fs.cwd().openFile(selected_file.?, .{})) |rom| {
                        defer rom.close();
                        if (rom.readToEndAlloc(buffer.allocator, 4096)) |data| {
                            try buffer.appendSlice(data);
                            var rom_data: []const u8 = buffer.items;
                            chip.load(&rom_data);
                            game_state = .running;
                        } else |_| {}
                    } else |_| {}
                }
            },
            .running => {
                for (game_keys) |key| {
                    if (ray.IsKeyDown(key)) {
                        if (key2btn(key)) |k| {
                            chip.keypress(k, true);
                        }
                    }

                    if (ray.IsKeyUp(key)) {
                        if (key2btn(key)) |k| {
                            chip.keypress(k, false);
                        }
                    }
                }

                for (0..TICKS_PER_FRAME) |_| {
                    chip.tick();
                }

                if (chip.tickTimers()) {
                    result = ma.ma_engine_play_sound(&engine, "public/beep-02.wav", null);

                    if (result != ma.MA_SUCCESS) {
                        std.debug.print("ma_engine_play_sound failed: {}\n", .{result});
                        return MiniAudioErrors.PlaySoundFailed;
                    }
                }

                drawScreen(&chip);
            },
        }
    }
}
