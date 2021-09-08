const std = @import("std");
const builtin = std.builtin;

// A 32-bit to 32-bit integer hash copied from Murmur3.
fn fmix(h: u32) u32 {
    var h1: u32 = h;
    h1 ^= h1 >> 16;
    h1 *%= 0x85ebca6b;
    h1 ^= h1 >> 13;
    h1 *%= 0xc2b2ae35;
    h1 ^= h1 >> 16;
    return h1;
}

// Rotate right helper
fn rotr32(x: u32, comptime r: u32) u32 {
    return (x >> r) | (x << (32 - r));
}

// Magic numbers for 32-bit hashing. Copied from Murmur3.
const c1: u32 = 0xcc9e2d51;
const c2: u32 = 0x1b873593;

// Helper from Murmur3 for combining two 32-bit values.
fn mur(a: u32, h: u32) u32 {
    var a1: u32 = a;
    var h1: u32 = h;
    a1 *%= c1;
    a1 = rotr32(a1, 17);
    a1 *%= c2;
    h1 ^= a1;
    h1 = rotr32(h1, 19);
    return h1 *% 5 +% 0xe6546b64;
}

fn hash32Len0To4(str: []const u8, comptime len: u32) u32 {
    var b: u32 = 0;
    var c: u32 = 9;
    comptime var i: u32 = 0;
    inline while (i < len) : (i += 1) {
        b = b *% c1 +% @bitCast(u32, @intCast(i32, @bitCast(i8, str[i])));
        c ^= b;
    }
    return fmix(mur(b, mur(len, c)));
}

inline fn fetch32(ptr: [*]const u8, offset: usize) u32 {
    return std.mem.readIntLittle(u32, @ptrCast([*]const u8, &ptr[offset])[0..4]);
}

fn hash32Len5To12(str: []const u8, comptime len: u32) u32 {
    const d: u32 = len *% 5;
    var a: u32 = len;
    var b: u32 = d;
    var c: u32 = 9;

    a +%= fetch32(str.ptr, 0);
    b +%= fetch32(str.ptr, len - 4);
    c +%= fetch32(str.ptr, (len >> 1) & 4);

    return fmix(mur(c, mur(b, mur(a, d))));
}

pub inline fn hash(str: []const u8, comptime len: u32) u32 {
    if (len < 5) {
        return hash32Len0To4(str, len);
    } else {
        return hash32Len5To12(str, len);
    }
}
