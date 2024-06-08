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
    desktop_bin.addIncludePath(.{
        .cwd_relative = ".packages/raylib/zig-out/include",
    });
    desktop_bin.addObjectFile(.{ .cwd_relative = ".packages/raylib/zig-out/lib/libraylib.a" });
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
}
