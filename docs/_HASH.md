```c
pub fn StringHashMap(comptime V: type) type {
    return HashMap([]const u8, V, StringContext, default_max_load_percentage);
}

pub const StringContext = struct {
    pub fn hash(self: @This(), s: []const u8) u64 {
        _ = self;
        return hashString(s);
    }
    pub fn eql(self: @This(), a: []const u8, b: []const u8) bool {
        _ = self;
        return eqlString(a, b);
    }
};

pub fn eqlString(a: []const u8, b: []const u8) bool {
    return mem.eql(u8, a, b);
}

pub fn hashString(s: []const u8) u64 {
    return std.hash.Wyhash.hash(0, s);
}

/// Fast non-cryptographic 64bit hash function.
/// See https://github.com/wangyi-fudan/wyhash
```

`wyhash.zig` according to that fork of smhasher it is the fastest non-cryptographic hash function without qualiy issues. 

https://github.com/wangyi-fudan/wyhash/raw/master/Modern%20Non-Cryptographic%20Hash%20Function%20and%20Pseudorandom%20Number%20Generator.pdf

# The FASTEST QUALITY hash function, random number generators (PRNG) and hash map.
## No hash function is perfect, but some are useful.

https://github.com/wangyi-fudan/wyhash

wyhash is the default hasher for a hash table of the great Zig, V and Nim language.
wyhash and wyrand are the ideal 64-bit hash function and PRNG respectively:

solid: wyhash passed SMHasher, wyrand passed BigCrush, practrand.

portable: 64-bit/32-bit system, big/little endian.

fastest: Efficient on 64-bit machines, especially for short keys.

simplest: In the sense of code size.
