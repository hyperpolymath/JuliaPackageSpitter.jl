// JULIAPACKAGESPITTER FFI Build Configuration
// SPDX-License-Identifier: MPL-2.0
//
// Targets Zig 0.14.x. Other versions fail to compile this file: the build API
// changed between releases (see ffi/zig/README or the PR notes).

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Shared library (.so, .dylib, .dll)
    const lib = b.addSharedLibrary(.{
        .name = "juliapackagespitter",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .version = .{ .major = 0, .minor = 1, .patch = 0 },
    });

    // Static library (.a)
    const lib_static = b.addStaticLibrary(.{
        .name = "juliapackagespitter",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // The allocator is c_allocator, so every artifact links libc.
    lib.linkLibC();
    lib_static.linkLibC();

    // Install artifacts
    b.installArtifact(lib);
    b.installArtifact(lib_static);

    // Install the hand-written C header
    b.installFile("include/juliapackagespitter.h", "include/juliapackagespitter.h");

    // Unit tests (src/main.zig)
    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_tests = b.addRunArtifact(lib_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_lib_tests.step);

    // Integration tests (test/integration_test.zig), linked against the library
    const integration_tests = b.addTest(.{
        .root_source_file = b.path("test/integration_test.zig"),
        .target = target,
        .optimize = optimize,
    });

    integration_tests.linkLibrary(lib);
    lib_tests.linkLibC();
    integration_tests.linkLibC();

    const run_integration_tests = b.addRunArtifact(integration_tests);

    const integration_test_step = b.step("test-integration", "Run integration tests");
    integration_test_step.dependOn(&run_integration_tests.step);

    // `zig build test` runs both suites
    test_step.dependOn(&run_integration_tests.step);
}
