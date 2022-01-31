const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("telexify", "src/telexify.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    // Build 1,2,3,4-gram models
    const ngram = b.addExecutable("telegram", "src/telegram.zig");
    ngram.setTarget(target);
    ngram.setBuildMode(mode);
    ngram.install();

    // Test all
    const all_tests = b.addTest("src/test.zig");
    all_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&all_tests.step);
}
