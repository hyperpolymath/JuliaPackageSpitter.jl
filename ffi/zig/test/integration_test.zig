// JULIAPACKAGESPITTER Integration Tests
// SPDX-License-Identifier: MPL-2.0
//
// These tests call the library through its C ABI (include/juliapackagespitter.h),
// linked against the built library. They check the template FFI described in
// src/main.zig; they do not check an Idris2 ABI, which does not exist here.

const std = @import("std");
const testing = std.testing;

// Import FFI functions. The handle is an opaque pointer on the C side.
extern fn juliapackagespitter_init() ?*anyopaque;
extern fn juliapackagespitter_free(?*anyopaque) void;
extern fn juliapackagespitter_process(?*anyopaque, u32) c_int;
extern fn juliapackagespitter_get_string(?*anyopaque) ?[*:0]const u8;
extern fn juliapackagespitter_free_string(?[*:0]const u8) void;
extern fn juliapackagespitter_last_error() ?[*:0]const u8;
extern fn juliapackagespitter_version() [*:0]const u8;
extern fn juliapackagespitter_is_initialized(?*anyopaque) u32;

//==============================================================================
// Lifecycle Tests
//==============================================================================

test "create and destroy handle" {
    const handle = juliapackagespitter_init() orelse return error.InitFailed;
    defer juliapackagespitter_free(handle);

    // init returned a non-null pointer, or the orelse above would have returned.
    try testing.expectEqual(@as(u32, 1), juliapackagespitter_is_initialized(handle));
}

test "handle is initialized" {
    const handle = juliapackagespitter_init() orelse return error.InitFailed;
    defer juliapackagespitter_free(handle);

    const initialized = juliapackagespitter_is_initialized(handle);
    try testing.expectEqual(@as(u32, 1), initialized);
}

test "null handle is not initialized" {
    const initialized = juliapackagespitter_is_initialized(null);
    try testing.expectEqual(@as(u32, 0), initialized);
}

//==============================================================================
// Operation Tests
//==============================================================================

test "process with valid handle" {
    const handle = juliapackagespitter_init() orelse return error.InitFailed;
    defer juliapackagespitter_free(handle);

    const result = juliapackagespitter_process(handle, 42);
    try testing.expectEqual(@as(c_int, 0), result); // 0 = ok
}

test "process with null handle returns error" {
    const result = juliapackagespitter_process(null, 42);
    try testing.expectEqual(@as(c_int, 4), result); // 4 = null_pointer
}

//==============================================================================
// String Tests
//==============================================================================

test "get string result" {
    const handle = juliapackagespitter_init() orelse return error.InitFailed;
    defer juliapackagespitter_free(handle);

    const str = juliapackagespitter_get_string(handle) orelse return error.NullString;
    defer juliapackagespitter_free_string(str);

    try testing.expectEqualStrings("Example result", std.mem.span(str));
}

test "get string with null handle" {
    const str = juliapackagespitter_get_string(null);
    try testing.expect(str == null);
}

//==============================================================================
// Error Handling Tests
//==============================================================================

test "last error after null handle operation" {
    _ = juliapackagespitter_process(null, 0);

    const err = juliapackagespitter_last_error() orelse return error.NoError;
    try testing.expect(std.mem.span(err).len > 0);
}

test "no error after successful operation" {
    const handle = juliapackagespitter_init() orelse return error.InitFailed;
    defer juliapackagespitter_free(handle);

    // A failing call sets an error; a successful one must clear it.
    _ = juliapackagespitter_process(null, 0);
    try testing.expect(juliapackagespitter_last_error() != null);

    try testing.expectEqual(@as(c_int, 0), juliapackagespitter_process(handle, 0));
    try testing.expect(juliapackagespitter_last_error() == null);
}

//==============================================================================
// Version Tests
//==============================================================================

test "version string is not empty" {
    const ver = juliapackagespitter_version();
    const ver_str = std.mem.span(ver);

    try testing.expect(ver_str.len > 0);
}

test "version string is semantic version format" {
    const ver = juliapackagespitter_version();
    const ver_str = std.mem.span(ver);

    // Should be in format X.Y.Z
    try testing.expect(std.mem.count(u8, ver_str, ".") >= 1);
}

//==============================================================================
// Memory Safety Tests
//==============================================================================

test "multiple handles are independent" {
    const h1 = juliapackagespitter_init() orelse return error.InitFailed;
    defer juliapackagespitter_free(h1);

    const h2 = juliapackagespitter_init() orelse return error.InitFailed;
    defer juliapackagespitter_free(h2);

    try testing.expect(h1 != h2);

    // Operations on h1 should not affect h2
    _ = juliapackagespitter_process(h1, 1);
    _ = juliapackagespitter_process(h2, 2);
}

test "free null is safe" {
    juliapackagespitter_free(null); // Documented no-op
}

//==============================================================================
// Thread Safety Tests
//==============================================================================

test "concurrent operations" {
    const handle = juliapackagespitter_init() orelse return error.InitFailed;
    defer juliapackagespitter_free(handle);

    const ThreadContext = struct {
        h: *anyopaque,
        id: u32,
    };

    const thread_fn = struct {
        fn run(ctx: ThreadContext) void {
            _ = juliapackagespitter_process(ctx.h, ctx.id);
        }
    }.run;

    var threads: [4]std.Thread = undefined;
    for (&threads, 0..) |*thread, i| {
        thread.* = try std.Thread.spawn(.{}, thread_fn, .{
            ThreadContext{ .h = handle, .id = @intCast(i) },
        });
    }

    for (threads) |thread| {
        thread.join();
    }
}
