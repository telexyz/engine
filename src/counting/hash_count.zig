// Modified from https://raw.githubusercontent.com/lithdew/rheia/master/hash_map.zig
const std = @import("std");

const mem = std.mem;
const math = std.math;
const testing = std.testing;

const assert = std.debug.assert;

pub fn AutoStaticHashCount(comptime K: type, comptime capacity: usize) type {
    return StaticHashCount(K, std.hash_map.AutoContext(K), capacity);
}

pub fn StaticHashCount(comptime K: type, comptime Context: type, comptime capacity: usize) type {
    assert(math.isPowerOfTwo(capacity));

    const shift = 63 - math.log2_int(u64, capacity) + 1;
    const overflow = capacity / 10 + (63 - @as(u64, shift) + 1) << 1;
    const size: usize = capacity + overflow;

    return struct {
        const empty_hash = math.maxInt(u64);

        pub const Entry = struct {
            hash: u64 = empty_hash,
            key: K = undefined,
            count: u24 = undefined,
        };

        const Self = @This();

        entries: [size]Entry = [_]Entry{.{}} ** size,
        len: usize = 0,
        shift: u6 = shift,

        put_probe_count: usize = 0,
        get_probe_count: usize = 0,
        del_probe_count: usize = 0,

        pub fn slice(self: *Self) []Self.Entry {
            return self.entries[0..size];
        }

        pub fn put(self: *Self, key: K) u24 {
            return self.putContext(key, undefined);
        }

        pub fn putContext(self: *Self, key: K, ctx: Context) u24 {
            var it: Self.Entry = .{ .hash = ctx.hash(key), .key = key, .count = 1 };
            var i = it.hash >> self.shift;

            // std.debug.print("\nhash: {}, i: {}\n", .{ it.hash, i });//DEBUG
            assert(it.hash != Self.empty_hash);

            while (true) : (i += 1) {
                const entry = self.entries[i];
                if (entry.hash >= it.hash) {
                    if (ctx.eql(entry.key, key)) {
                        self.entries[i].count += 1;
                        return entry.count + 1;
                    }
                    self.entries[i] = it;
                    if (entry.hash == empty_hash) {
                        self.len += 1;
                        return 1;
                    }
                    it = entry;
                }
                self.put_probe_count += 1;
            }
        }

        pub fn get(self: *Self, key: K) u24 {
            return self.getContext(key, undefined);
        }

        pub fn getContext(self: *Self, key: K, ctx: Context) u24 {
            const hash = ctx.hash(key);

            var i = hash >> self.shift;
            while (true) : (i += 1) {
                const entry = self.entries[i];
                if (entry.hash >= hash) {
                    if (!ctx.eql(entry.key, key)) {
                        return 0;
                    }
                    return entry.count;
                }
                self.get_probe_count += 1;
            }
        }
    };
}

test "StaticHashCount: put, get" {
    var seed: usize = 0;
    while (seed < 128) : (seed += 1) {
        var counters: AutoStaticHashCount(usize, 512) = .{};
        var rng = std.rand.DefaultPrng.init(seed);

        const keys = try testing.allocator.alloc(usize, 512);
        defer testing.allocator.free(keys);

        for (keys) |*key| key.* = rng.random.int(usize);

        try testing.expectEqual(@as(u6, 55), counters.shift);

        for (keys) |key| {
            try testing.expectEqual(@as(u24, 1), counters.put(key));
        }

        try testing.expectEqual(keys.len, counters.len);

        for (keys) |key| {
            try testing.expectEqual(@as(u24, 2), counters.put(key));
        }

        try testing.expectEqual(keys.len, counters.len);

        for (keys) |key| try testing.expectEqual(@as(u24, 2), counters.get(key));
    }
}
