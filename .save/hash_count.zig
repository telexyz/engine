// Modified from https://raw.githubusercontent.com/lithdew/rheia/master/hash_map.zig
const std = @import("std");

const math = std.math;
const mem = std.mem;
const Allocator = mem.Allocator;

const fvn1a32 = @import("../hashing/fvn1a32.zig");
const cityhash32 = @import("../hashing/cityhash32.zig");
const XXHash32 = @import("../hashing/xxhash.zig").XXHash32;

pub fn HashCount123(comptime K: type, comptime capacity: u32) type {
    return HashCount(K, capacity, u32, u16, u24); // 9-bytes (4 + 2 + 3)
}

pub fn HashCount456(comptime K: type, comptime capacity: u32) type {
    return HashCount(K, capacity, u32, u24, u16); // 9-bytes (4 + 3 + 2)
}

// args: key type, capacity, hash type, fingerprint type, count type
fn HashCount(comptime K: type, comptime capacity: u32, comptime H: type, comptime F: type, comptime C: type) type {
    std.debug.assert(math.isPowerOfTwo(capacity));
    const shift = 31 - math.log2_int(u32, capacity) + 1;
    const overflow = capacity / 10 + math.log2_int(u32, capacity) << 1;
    const size: usize = capacity + overflow;

    const maxx_hash = math.maxInt(H);
    const fp_bits = @typeInfo(F).Int.bits;

    const R = @Type(std.builtin.TypeInfo{ .Int = .{
        .signedness = .unsigned,
        .bits = fp_bits + @typeInfo(H).Int.bits,
    } });

    // const T = @Type(std.builtin.TypeInfo{ .Int = .{
    //     .signedness = .unsigned,
    //     .bits = fp_bits - 2,
    // } });

    const key_len: u32 = @typeInfo(K).Array.len;
    const key_lfp = if (key_len < 4) key_len else @rem(key_len, 4) + 1;

    return struct {
        pub const bytes = (fp_bits + @typeInfo(H).Int.bits + @typeInfo(C).Int.bits) / 8;
        pub const HashType = H;
        pub const CountType = C;
        pub const fp_head = @intCast(F, key_lfp) << (fp_bits - 2);

        pub const Entry = struct {
            hash: H = maxx_hash,
            fp: F = 0,
            count: C = 0,
            pub fn keyRepresent(self: Entry) R {
                return (@intCast(R, self.hash) << fp_bits) | self.fp;
            }
        };
        // 2-bits ?????u c???a fp ????? d??i n-gram ???????c t??nh s???n ??? fp_head

        const Self = @This();

        allocator: Allocator = undefined,
        entries: []Entry = undefined,
        len: usize = undefined,

        pub fn init(self: *Self, init_allocator: Allocator) !void {
            self.allocator = init_allocator;
            self.len = 0;

            self.entries = try self.allocator.alloc(Entry, size);
            mem.set(Entry, self.entries, .{ .hash = maxx_hash, .count = 0 });
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.entries);
        }

        pub fn slice(self: Self) []Self.Entry {
            return self.entries[0..size];
        }

        inline fn _hash(key: K) H {
            // const hash = XXHash32.hash(0, mem.asBytes(&key));
            const hash = cityhash32.hash(mem.asBytes(&key), 2 * key_len);
            return @truncate(H, hash);
        }

        inline fn _fingerprint(key: K) F {
            const hash = fvn1a32.hash(fvn1a32.init_offset, u16, &key, key_len);
            return @truncate(F, hash);
        }

        pub inline fn put(self: *Self, key: K) C {
            return self.put_with_fp(key, _fingerprint(key));
        }

        pub fn put_with_fp(self: *Self, key: K, fp: F) C {
            // T??? key ta d??ng hash functions ????? kh???i t???o gi?? tr??? hash v?? fingerprint
            // S??? d???ng hash + fingerprint ????? ?????i di???n cho key
            // => c???n m?? ????? l???n c???a fingerprint h???p l?? ????? tr??nh va ch???m
            var it: Self.Entry = .{
                .hash = _hash(key),
                .fp = fp,
                .count = 1,
            };

            // S??? d???ng capacity isPowerOfTwo v?? d??ng h??m shift ????? b??m hash v??o index.
            // Nh??? d??ng right-shift n??n gi??? ???????c bit cao c???a hash value trong index
            // V???y n??n ?????m b???o t??nh t??ng d???n c???a hash value (clever trick 1)
            var i = it.hash >> shift;

            while (true) : (i += 1) {
                const entry = self.entries[i];

                // V?? hash ???? ???????c kh???i t???p s???n ??? maxx_hash value n??n ?????m b???o slot tr???ng
                // c?? hash value >= gi?? tr??? hash ??ang xem x??t (clever trick 2)
                if (entry.hash >= it.hash) {

                    // Gi??? thi???t r???ng hash + fingerprint l?? uniq v???i m???i key
                    // N??n thay v?? if (meta.eql(entry.key, key)) ta d??ng
                    if (entry.fp == fp and entry.hash == it.hash) {
                        // T??m ???????c ????ng ?? ch???a, t??ng count l??n 1 and return :)
                        self.entries[i].count += 1;
                        return entry.count + 1;
                    }

                    // Kh??ng ????ng ?? ch???a m?? hash c???a ?? l???i l???n h??n th?? ta ghi ????? gi?? tr???
                    // c???a it v??o ????
                    self.entries[i] = it;

                    // N???u ?? ???? l?? ?? r???ng, count == 0 ngh??a l?? ch??a l??u g?? c???, th??
                    // key ?????u v??o l???n ?????u xu???t hi???n, ta t??ng len v?? return :D
                    if (entry.count == 0) {
                        self.len += 1;
                        return 1;
                    }

                    // Tr??o gi?? tr??? it v?? entries[i] ???? ???????c l??u v??o entry tr??? tr?????c
                    // ????? ?????m b???o t??nh t??ng d???n c???a hash value
                    it = entry;
                }
            } // while
        }

        pub fn get(self: *Self, key: K) C {
            const fp = _fingerprint(key);
            const hash = _hash(key);

            var i = hash >> shift;
            // V?? hash value lu??n t??ng n??n khi entry.hash > hash ngh??a l?? hash ch??a dc ?????m
            while (true) : (i += 1) {
                const entry = self.entries[i];
                if (entry.hash >= hash) {
                    if (entry.fp == fp and entry.hash == hash) return entry.count;
                    return 0;
                }
            }
        }
    };
}

const testing = std.testing;
test "HashCount123: fp_head" {
    try testing.expectEqual(0b01000000_00000000, HashCount123([1]usize, 8).fp_head);
    try testing.expectEqual(0b10000000_00000000, HashCount123([2]usize, 8).fp_head);
    try testing.expectEqual(0b11000000_00000000, HashCount123([3]usize, 8).fp_head);
}

test "HashCount123: put, get" {
    const HC = HashCount123([2]u16, 512);
    try testing.expectEqual(9, HC.bytes);
    try testHC(HC);
}

test "HashCount456: fingerprint_header" {
    try testing.expectEqual(0b01000000_00000000_00000000, HashCount456([4]usize, 8).fp_head);
    try testing.expectEqual(0b10000000_00000000_00000000, HashCount456([5]usize, 8).fp_head);
    try testing.expectEqual(0b11000000_00000000_00000000, HashCount456([6]usize, 8).fp_head);
}

test "HashCount456: put, get" {
    const HC = HashCount456([2]u16, 512);
    try testing.expectEqual(9, HC.bytes);
    try testHC(HC);
}

fn testHC(comptime HC: type) !void {
    var counters: HC = undefined;
    var seed: usize = 0;

    while (seed < 128) : (seed += 1) {
        const my_allocator = std.heap.page_allocator;
        try counters.init(my_allocator);
        defer counters.deinit();

        const keys = try my_allocator.alloc(usize, 512);
        defer my_allocator.free(keys);
        var rng = std.rand.DefaultPrng.init(seed);
        const random = rng.random();

        for (keys) |*key, i| {
            key.* = random.int(usize);
            try testing.expectEqual(@as(HC.CountType, 1), counters.put(.{
                @truncate(u16, i),
                @truncate(u16, key.*),
            }));
        }
        try testing.expectEqual(keys.len, counters.len);

        var hash: HC.HashType = 0;
        for (counters.slice()) |entry|
            if (entry.count != 0) {
                if (hash > entry.hash) return error.Unsorted;
                hash = entry.hash;
            };

        for (keys) |key, i| try testing.expectEqual(@as(HC.CountType, 1), counters.get(.{
            @truncate(u16, i),
            @truncate(u16, key),
        }));
    }
}
