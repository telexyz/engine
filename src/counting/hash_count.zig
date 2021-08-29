// Modified from https://raw.githubusercontent.com/lithdew/rheia/master/hash_map.zig
const std = @import("std");

const mem = std.mem;
const math = std.math;
const Allocator = mem.Allocator;
const Wyhash = std.hash.Wyhash;

const testing = std.testing;
const assert = std.debug.assert;

pub fn AutoHashCount(comptime K: type, comptime capacity: usize) type {
    return HashCount(K, std.hash_map.AutoContext(K), capacity);
}

pub fn HashCount(comptime K: type, comptime Context: type, comptime capacity: usize) type {
    assert(math.isPowerOfTwo(capacity));

    const shift = 63 - math.log2_int(u64, capacity) + 1;
    const overflow = capacity / 10 + (63 - @as(u64, shift) + 1) << 1;
    const size: usize = capacity + overflow;

    return struct {
        const empty_hash = math.maxInt(u64);

        pub const Entry = struct {
            hash: u64 = empty_hash,
            key: K = undefined,
            count: u24 = 0,
        };

        const Self = @This();

        allocator: *Allocator = undefined,
        entries: []Entry = undefined,
        len: usize = undefined,
        shift: u6 = undefined,
        put_probe_count: usize = undefined,
        get_probe_count: usize = undefined,

        pub fn init(self: *Self, init_allocator: *Allocator) !void {
            self.allocator = init_allocator;
            self.len = 0;
            self.shift = shift;
            self.put_probe_count = 0;
            self.get_probe_count = 0;

            self.entries = try self.allocator.alloc(Entry, size);
            mem.set(Entry, self.entries, .{ .hash = empty_hash });
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.entries);
        }

        pub fn slice(self: *Self) []Self.Entry {
            return self.entries[0..size];
        }

        pub fn put(self: *Self, key: K) u24 {
            return self.putContext(key, undefined);
        }

        pub fn putContext(self: *Self, key: K, ctx: Context) u24 {
            var it: Self.Entry = .{ .hash = ctx.hash(key), .key = key, .count = 1 };
            var i = it.hash >> self.shift;

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

test "HashCount: put, get" {
    var seed: usize = 0;
    var counters: AutoHashCount(usize, 512) = .{};

    while (seed < 128) : (seed += 1) {
        try counters.init(testing.allocator);
        defer counters.deinit();

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
