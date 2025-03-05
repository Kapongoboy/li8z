const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const backend = b.addStaticLibrary(.{
        .name = "li8z",
        .root_source_file = b.path("src/backend.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(backend);

    const desktop_bin = b.addExecutable(.{
        .name = "li8z",
        .root_source_file = b.path("src/desktop.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zaudio = b.dependency("zaudio", .{});
    desktop_bin.root_module.addImport("zaudio", zaudio.module("root"));
    desktop_bin.linkLibrary(zaudio.artifact("miniaudio"));
    const desktop_includes = [_][]const u8{
        ".packages/raylib/build/raylib/include",
        ".packages/tinyfiledialogs",
        ".packages/raygui/src",
    };

    for (desktop_includes) |include_path| {
        desktop_bin.addIncludePath(b.path(include_path));
    }

    desktop_bin.addCSourceFile(.{ .file = b.path(".packages/tinyfiledialogs/tinyfiledialogs.c") });
    desktop_bin.addObjectFile(b.path(".packages/raylib/build/raylib/libraylib.a"));
    desktop_bin.linkLibC();

    b.installArtifact(desktop_bin);

    const run_cmd = b.addRunArtifact(desktop_bin);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/backend.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/desktop.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);

    // Add WASM compilation target
    const wasm_mod = b.createModule(.{
        .root_source_file = b.path("src/web.zig"),
        .target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding }),
        .optimize = optimize,
    });

    wasm_mod.export_symbol_names = &[_][]const u8{
        "initEmulator",
        "tickEmulator",
        "tickTimers",
        "keyPress",
        "getScreenPtr",
        "loadROM",
        "resetEmulator",
        "getScreenWidth",
        "getScreenHeight",
    };

    const wasm = b.addExecutable(.{
        .linkage = .static,
        .name = "li8z-web",
        .root_module = wasm_mod,
    });

    // Configure WASM output
    wasm.rdynamic = true;
    wasm.export_memory = true;
    wasm.import_memory = true;
    wasm.initial_memory = 17 * 64 * 1024; // 17 pages (~1.1MB)
    wasm.max_memory = 17 * 64 * 1024;
    wasm.entry = .disabled;
    // Install WASM artifact with custom name
    const install_wasm = b.addInstallArtifact(wasm, .{});

    // Add a build step specifically for WASM
    const wasm_step = b.step("wasm", "Build the WebAssembly library");
    wasm_step.dependOn(&install_wasm.step);
}
