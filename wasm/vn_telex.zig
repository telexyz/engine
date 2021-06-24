const std = @import("std");
const fmt = std.fmt;
const parseAmTietToGetSyllable = @import("./src/parsers.zig").parseAmTietToGetSyllable;

// Flexible print function so it can print debug info to various
// runtime environment (e.g: native, wasm ...), or just do nothing :^)
fn print(comptime fmt_str: []const u8, args: anytype) void {
    // std.debug.print(fmt_str, args);
    // printAndLog(fmt_str, args);
}

// - - - - - - - - - - - -
// Begin wasm related code

var message_ptr: [*]u8 = undefined;

extern fn logString(size: usize, index: [*]const u8) void;
extern fn logStr(index: [*]const u8) void;
extern fn printResult(i32) void;

// printAndLog may overwrite memory used by wasmCanBeVietnamese to return the value back to the js host. Need to verify by putting message_ptr futher more from 0 (say 300 for example)
fn printAndLog(comptime fmt_str: []const u8, args: anytype) void {
    // https://ziglang.org/documentation/master/#Slices
    // You can use slice syntax on an array to convert an array into a slice.
    var message_array: [300]u8 = undefined;
    const message_slice = message_array[0..];

    const message_str = fmt.bufPrint(message_slice, fmt_str, args) catch "ERROR";
    for (message_str) |b, i| message_ptr[i] = b;
    // The optimizer is intelligent enough to turn the above snippet into a memcpy.
    // @memcpy(noalias dest: [*]u8, noalias source: [*]const u8, byte_count: usize)

    logString(message_str.len, message_ptr);
}

pub export fn wasmCanBeVietnamese(start: usize, size: usize, mem_ptr: [*]u8) bool {
    message_ptr = mem_ptr;

    const am_tiet: []const u8 = mem_ptr[start .. start + size];
    const result = parseAmTietToGetSyllable(print, am_tiet).can_be_vietnamese;

    // printStr(am_tiet);
    // printResult(if (result) 1 else 0);
    return result;
}

// End wasm related code
// - - - - - - - - - - -
