// Modified from https://raw.githubusercontent.com/lithdew/rheia/master/hash_map.zig
const std = @import("std");

const math = std.math;
const mem = std.mem;
const Allocator = mem.Allocator;

const fvn1a32 = @import("../hashing/fvn1a32.zig");

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

    const key_len = @typeInfo(K).Array.len;
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
        // 2-bits đầu của fp độ dài n-gram được tính sẵn ở fp_head

        const Self = @This();

        allocator: *Allocator = undefined,
        entries: []Entry = undefined,
        len: usize = undefined,

        pub fn init(self: *Self, init_allocator: *Allocator) !void {
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
            const hash = std.hash.CityHash32.hash(mem.asBytes(&key));
            return @truncate(H, hash);
        }

        inline fn _fingerprint(key: K) F {
            var hash = fvn1a32.hash(fvn1a32.init_offset, u16, &key, key_len);
            return @truncate(F, hash);
        }

        pub fn put(self: *Self, key: K) C {
            // Từ key ta dùng hash functions để khởi tạo giá trị hash và fingerprint
            // Sử dụng hash + fingerprint để đại diện cho key
            // => cần mò độ lớn của fingerprint hợp lý để tránh va chạm
            const fp = _fingerprint(key);
            var it: Self.Entry = .{
                .hash = _hash(key),
                .fp = fp,
                .count = 1,
            };

            // Sử dụng capacity isPowerOfTwo và dùng hàm shift để băm hash vào index.
            // Nhờ dùng right-shift nên giữ được bit cao của hash value trong index
            // Vậy nên đảm bảo tính tăng dần của hash value (clever trick 1)
            var i = it.hash >> shift;

            while (true) : (i += 1) {
                const entry = self.entries[i];

                // Vì hash đã được khởi tạp sẵn ở maxx_hash value nên đảm bảo slot trống
                // có hash value >= giá trị hash đang xem xét (clever trick 2)
                if (entry.hash >= it.hash) {

                    // Giả thiết rằng hash + fingerprint là uniq với mỗi key
                    // Nên thay vì if (meta.eql(entry.key, key)) ta dùng
                    if (entry.fp == fp and entry.hash == it.hash) {
                        // Tìm được đúng ô chứa, tăng count lên 1 and return :)
                        self.entries[i].count += 1;
                        return entry.count + 1;
                    }

                    // Không đúng ô chứa mà hash của ô lại lớn hơn thì ta ghi đề giá trị
                    // của it vào đó
                    self.entries[i] = it;

                    // Nếu ô đó là ô rỗng, count == 0 nghĩa là chưa lưu gì cả, thì
                    // key đầu vào lần đầu xuất hiện, ta tăng len và return :D
                    if (entry.count == 0) {
                        self.len += 1;
                        return 1;
                    }

                    // Tráo giá trị it và entries[i] đã được lưu vào entry trừ trước
                    // để đảm bảo tính tăng dần của hash value
                    it = entry;
                }
            } // while
        }

        pub fn get(self: *Self, key: K) C {
            const fp = _fingerprint(key);
            const hash = _hash(key);

            var i = hash >> shift;
            // Vì hash value luôn tăng nên khi entry.hash > hash nghĩa là hash chưa dc đếm
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
        try counters.init(testing.allocator);
        defer counters.deinit();

        const keys = try testing.allocator.alloc(usize, 512);
        defer testing.allocator.free(keys);
        var rng = std.rand.DefaultPrng.init(seed);

        for (keys) |*key, i| {
            key.* = rng.random.int(usize);
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
