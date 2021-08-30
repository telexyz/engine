// Modified from https://raw.githubusercontent.com/lithdew/rheia/master/hash_map.zig
const std = @import("std");

const mem = std.mem;
const math = std.math;
const meta = std.meta;

const Allocator = mem.Allocator;

pub fn HashCount(comptime K: type, capacity: usize) type {
    const overflow = capacity / 10 + math.log2_int(u64, capacity) << 1;
    const size: usize = capacity + overflow;

    return struct {
        pub const Fingerprint = u32;
        pub const HashType = u32;
        pub const empty_hash = math.maxInt(HashType);
        pub const Entry = struct {
            hash: HashType = empty_hash,
            fp: Fingerprint = 0,
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

        inline fn _hash(key: K) HashType {
            return @truncate(HashType, std.hash.CityHash32.hash(mem.asBytes(&key)));
        }

        inline fn _fingerprint(key: K) Fingerprint {
            const hash = std.hash.Fnv1a_32.hash(mem.asBytes(&key));
            return (@intCast(Fingerprint, key.len) << 29) | @truncate(u29, hash);
        }

        pub fn put(self: *Self, key: K) u24 {
            const fp = _fingerprint(key);
            var it: Self.Entry = .{
                .hash = _hash(key),
                .fp = fp,
                .count = 1,
            };

            var i = @rem(it.hash, capacity);
            // var i = it.hash >> shift;
            while (true) : (i += 1) {
                const entry = self.entries[i];
                if (entry.hash >= it.hash) {
                    // if (meta.eql(entry.key, key)) {
                    if (entry.fp == fp and entry.hash == it.hash) {
                        self.entries[i].count += 1;
                        return entry.count + 1;
                    }
                    self.entries[i] = it;
                    if (entry.count == 0) {
                        self.len += 1;
                        return 1;
                    }
                    it = entry;
                }
            }
        }

        pub fn get(self: *Self, key: K) u24 {
            const fp = _fingerprint(key);
            const hash = _hash(key);

            var i = @rem(hash, capacity);
            // var i = hash >> shift;
            while (true) : (i += 1) {
                const entry = self.entries[i];
                if (entry.hash >= hash) {
                    // if (!meta.eql(entry.key, key)) {
                    if (entry.fp != fp) {
                        return 0;
                    }
                    return entry.count;
                }
            }
        }
    };
}

const testing = std.testing;
test "HashCount: put, get" {
    var seed: usize = 0;
    const HC = HashCount([1]usize, 512);
    var counters: HC = undefined;

    while (seed < 128) : (seed += 1) {
        try counters.init(testing.allocator);
        defer counters.deinit();

        var rng = std.rand.DefaultPrng.init(seed);

        const keys = try testing.allocator.alloc(usize, 512);
        defer testing.allocator.free(keys);

        for (keys) |*key| key.* = rng.random.int(usize);

        for (keys) |key, i| {
            if (@rem(i, 2) == 0)
                try testing.expectEqual(@as(u24, 1), counters.put(.{key}));
        }
        for (keys) |key, i| {
            if (@rem(i, 2) == 1)
                try testing.expectEqual(@as(u24, 1), counters.put(.{key}));
        }
        try testing.expectEqual(keys.len, counters.len);

        var hash: u32 = 0;
        for (counters.slice()) |entry| {
            if (entry.count != 0) {
                if (hash > entry.hash) {
                    // return error.Unsorted;
                }
                hash = entry.hash;
            }
        }
        for (keys) |key|
            try testing.expectEqual(@as(u24, 1), counters.get(.{key}));
    }
}
