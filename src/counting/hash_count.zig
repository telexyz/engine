// Modified from https://raw.githubusercontent.com/lithdew/rheia/master/hash_map.zig
const std = @import("std");

const mem = std.mem;
const math = std.math;
const meta = std.meta;

const Allocator = mem.Allocator;
const CityHash32 = std.hash.CityHash32;

const testing = std.testing;
const assert = std.debug.assert;

pub fn HashCount(comptime K: type, capacity: usize) type {
    const shift = 63 - math.log2_int(u64, capacity) + 1;
    const overflow = capacity / 10 + (64 - @as(u64, shift)) << 1;
    const size: usize = capacity + overflow;

    return struct {
        const empty_hash = math.maxInt(u32);

        pub const Entry = struct {
            hash: u32 = empty_hash,
            key: K = undefined,
            count: u24 = 0,
        };

        const Self = @This();

        allocator: *Allocator = undefined,
        entries: []Entry = undefined,
        len: usize = undefined,

        pub fn init(self: *Self, init_allocator: *Allocator) !void {
            self.allocator = init_allocator;
            self.len = 0;

            self.entries = try self.allocator.alloc(Entry, size);
            mem.set(Entry, self.entries, .{ .hash = empty_hash });
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.entries);
        }

        pub fn slice(self: Self) []Self.Entry {
            return self.entries[0..size];
        }

        pub fn put(self: *Self, key: K) u24 {
            var it: Self.Entry = .{
                .hash = CityHash32.hash(std.mem.asBytes(&key)),
                .key = key,
                .count = 1,
            };
            // var i = it.hash >> self.shift;
            var i = @rem(it.hash, capacity);

            assert(it.hash != Self.empty_hash);

            while (true) : (i += 1) {
                const entry = self.entries[i];
                if (entry.hash >= it.hash) {
                    if (meta.eql(entry.key, key)) {
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
            }
        }

        pub fn get(self: *Self, key: K) u24 {
            const hash = CityHash32.hash(std.mem.asBytes(&key));

            // var i = hash >> self.shift;
            var i = @rem(hash, capacity);
            while (true) : (i += 1) {
                const entry = self.entries[i];
                if (entry.hash >= hash) {
                    if (!meta.eql(entry.key, key)) {
                        return 0;
                    }
                    return entry.count;
                }
            }
        }
    };
}

test "HashCount: put, get" {
    var seed: usize = 0;
    var counters: HashCount(usize, 512) = undefined;

    while (seed < 128) : (seed += 1) {
        try counters.init(testing.allocator);
        defer counters.deinit();

        var rng = std.rand.DefaultPrng.init(seed);

        const keys = try testing.allocator.alloc(usize, 512);
        defer testing.allocator.free(keys);

        for (keys) |*key| key.* = rng.random.int(usize);

        for (keys) |key| {
            try testing.expectEqual(@as(u24, 1), counters.put(key));
        }
        try testing.expectEqual(keys.len, counters.len);

        for (keys) |key| {
            try testing.expectEqual(@as(u24, 2), counters.put(key));
        }
        try testing.expectEqual(keys.len, counters.len);

        // Only capacity is power of 2 then hash table is sorted
        // var it: usize = 0;
        // for (counters.slice()) |entry| {
        //     if (entry.count != 0) {
        //         if (it > entry.hash) {
        //             return error.Unsorted;
        //         }
        //         it = entry.hash;
        //     }
        // }
        for (keys) |key| try testing.expectEqual(@as(u24, 2), counters.get(key));
    }
}
