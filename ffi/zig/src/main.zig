// SPDX-License-Identifier: MPL-2.0
// JuliaPackageSpitter.jl FFI implementation (template).
//
// Working: library lifecycle (init/free/is_initialized), version and build
// info, the string round-trip (get_string/free_string), and last-error
// reporting.
//
// Placeholders: juliapackagespitter_process, juliapackagespitter_process_array
// and juliapackagespitter_register_callback validate their arguments and then
// do nothing else. They are examples, not behaviour.
//
// No Idris2 ABI exists in this repository (the Idris2 sources are not in the tree), so nothing here
// is checked against one. The C declarations are in include/juliapackagespitter.h.

const std = @import("std");

// Version information (keep in sync with project)
const VERSION = "0.1.0";
const BUILD_INFO = "JuliaPackageSpitter.jl built with Zig " ++ @import("builtin").zig_version_string;

/// Thread-local error storage. Only string literals are stored, so the pointer
/// stays valid for the life of the program and needs no freeing.
threadlocal var last_error: ?[*:0]const u8 = null;

/// Set the last error message (must be a string literal or other static string)
fn setError(msg: [*:0]const u8) void {
    last_error = msg;
}

/// Clear the last error
fn clearError() void {
    last_error = null;
}

//==============================================================================
// Core Types
//==============================================================================

/// Result codes
pub const Result = enum(c_int) {
    ok = 0,
    @"error" = 1,
    invalid_param = 2,
    out_of_memory = 3,
    null_pointer = 4,
};

/// Library handle. Its layout is private to this file; C sees only an opaque pointer.
pub const Handle = struct {
    allocator: std.mem.Allocator,
    initialized: bool,
};


//==============================================================================
// Library Lifecycle
//==============================================================================

/// Initialize the library
/// Returns a handle, or null on failure
export fn juliapackagespitter_init() ?*Handle {
    const allocator = std.heap.c_allocator;

    const handle = allocator.create(Handle) catch {
        setError("Failed to allocate handle");
        return null;
    };

    // Initialize handle
    handle.* = .{
        .allocator = allocator,
        .initialized = true,
    };

    clearError();
    return handle;
}

/// Free the library handle
export fn juliapackagespitter_free(handle: ?*Handle) void {
    const h = handle orelse return;
    const allocator = h.allocator;

    // Clean up resources
    h.initialized = false;

    allocator.destroy(h);
    clearError();
}

//==============================================================================
// Core Operations
//==============================================================================

/// Process data (example operation)
export fn juliapackagespitter_process(handle: ?*Handle, input: u32) Result {
    const h = handle orelse {
        setError("Null handle");
        return .null_pointer;
    };

    if (!h.initialized) {
        setError("Handle not initialized");
        return .@"error";
    }

    // Example processing logic
    _ = input;

    clearError();
    return .ok;
}

//==============================================================================
// String Operations
//==============================================================================

/// Get a string result (example)
/// Caller must free the returned string
export fn juliapackagespitter_get_string(handle: ?*Handle) ?[*:0]const u8 {
    const h = handle orelse {
        setError("Null handle");
        return null;
    };

    if (!h.initialized) {
        setError("Handle not initialized");
        return null;
    }

    // Example: allocate and return a string
    const result = h.allocator.dupeZ(u8, "Example result") catch {
        setError("Failed to allocate string");
        return null;
    };

    clearError();
    return result.ptr;
}

/// Free a string allocated by the library
export fn juliapackagespitter_free_string(str: ?[*:0]const u8) void {
    const s = str orelse return;
    const allocator = std.heap.c_allocator;

    // get_string allocated len+1 bytes (dupeZ includes the sentinel). The free
    // must pass that exact length, or the allocator is handed the wrong size.
    const slice = @constCast(s[0 .. std.mem.len(s) + 1]);
    allocator.free(slice);
}

//==============================================================================
// Array/Buffer Operations
//==============================================================================

/// Process an array of data
export fn juliapackagespitter_process_array(
    handle: ?*Handle,
    buffer: ?[*]const u8,
    len: u32,
) Result {
    const h = handle orelse {
        setError("Null handle");
        return .null_pointer;
    };

    const buf = buffer orelse {
        setError("Null buffer");
        return .null_pointer;
    };

    if (!h.initialized) {
        setError("Handle not initialized");
        return .@"error";
    }

    // Access the buffer
    const data = buf[0..len];
    _ = data;

    // Process data here

    clearError();
    return .ok;
}

//==============================================================================
// Error Handling
//==============================================================================

/// Get the last error message
/// Returns null if no error
export fn juliapackagespitter_last_error() ?[*:0]const u8 {
    // Static storage: the message is a string literal, so the caller must NOT free it.
    return last_error;
}

//==============================================================================
// Version Information
//==============================================================================

/// Get the library version
export fn juliapackagespitter_version() [*:0]const u8 {
    return VERSION.ptr;
}

/// Get build information
export fn juliapackagespitter_build_info() [*:0]const u8 {
    return BUILD_INFO.ptr;
}

//==============================================================================
// Callback Support
//==============================================================================

/// Callback function type (C ABI)
pub const Callback = *const fn (u64, u32) callconv(.C) u32;

/// Register a callback
export fn juliapackagespitter_register_callback(
    handle: ?*Handle,
    callback: ?Callback,
) Result {
    const h = handle orelse {
        setError("Null handle");
        return .null_pointer;
    };

    const cb = callback orelse {
        setError("Null callback");
        return .null_pointer;
    };

    if (!h.initialized) {
        setError("Handle not initialized");
        return .@"error";
    }

    // Store callback for later use
    _ = cb;

    clearError();
    return .ok;
}

//==============================================================================
// Utility Functions
//==============================================================================

/// Check if handle is initialized
export fn juliapackagespitter_is_initialized(handle: ?*Handle) u32 {
    const h = handle orelse return 0;
    return if (h.initialized) 1 else 0;
}

//==============================================================================
// Tests
//==============================================================================

test "lifecycle" {
    const handle = juliapackagespitter_init() orelse return error.InitFailed;
    defer juliapackagespitter_free(handle);

    try std.testing.expect(juliapackagespitter_is_initialized(handle) == 1);
}

test "error handling" {
    const result = juliapackagespitter_process(null, 0);
    try std.testing.expectEqual(Result.null_pointer, result);

    const err = juliapackagespitter_last_error();
    try std.testing.expect(err != null);
}

test "version" {
    const ver = juliapackagespitter_version();
    const ver_str = std.mem.span(ver);
    try std.testing.expectEqualStrings(VERSION, ver_str);
}
