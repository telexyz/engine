// Modified from https://raw.githubusercontent.com/lithdew/rheia/master/hash_map.zig
const std = @import("std");

const math = std.math;
const mem = std.mem;
const Allocator = mem.Allocator;

pub fn HashCount(comptime K: type, comptime capacity: u32) type {
    std.debug.assert(math.isPowerOfTwo(capacity));
    const shift = 31 - math.log2_int(u32, capacity) + 1;
    const overflow = capacity / 10 + math.log2_int(u32, capacity) << 1;
    const size: usize = capacity + overflow;

    return struct {
        pub const Fingerprint = u16;
        pub const fingerprint_header = @intCast(Fingerprint, @typeInfo(K).Array.len) << 14;

        pub const HashType = u32;
        pub const maxx_hash = math.maxInt(HashType);

        pub const CountType = u24;

        pub const Entry = struct {
            hash: HashType = maxx_hash,
            fp: Fingerprint = 0,
            count: CountType = 0,
            pub fn keyRepresent(self: Entry) u48 {
                return (@intCast(u48, self.hash) << 24) | self.fp;
            }
        };
        // fp chứa 22-bits từ 1 hàm hash và 2-bits chứa độ dài n-gram từ 1-3

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

        inline fn _hash(key: K) HashType {
            return std.hash.CityHash32.hash(mem.asBytes(&key));
        }

        inline fn _fingerprint(key: K) Fingerprint {
            const hash = std.hash.Fnv1a_32.hash(mem.asBytes(&key));
            return fingerprint_header | @truncate(u14, hash);
            // return @truncate(Fingerprint, hash);
        }

        pub fn put(self: *Self, key: K) CountType {
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

        pub fn get(self: *Self, key: K) CountType {
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
test "HashCount: fingerprint_header" {
    try testing.expectEqual(0b01000000_00000000, HashCount([1]usize, 8).fingerprint_header);
    try testing.expectEqual(0b10000000_00000000, HashCount([2]usize, 8).fingerprint_header);
    try testing.expectEqual(0b11000000_00000000, HashCount([3]usize, 8).fingerprint_header);
}

test "HashCount: put, get" {
    var seed: usize = 0;
    const HC = HashCount([1]usize, 512);
    var counters: HC = undefined;

    while (seed < 128) : (seed += 1) {
        try counters.init(testing.allocator);
        defer counters.deinit();

        const keys = try testing.allocator.alloc(usize, 512);
        defer testing.allocator.free(keys);
        var rng = std.rand.DefaultPrng.init(seed);

        for (keys) |*key| {
            key.* = rng.random.int(usize);
            try testing.expectEqual(@as(HC.CountType, 1), counters.put(.{key.*}));
        }
        try testing.expectEqual(keys.len, counters.len);

        var hash: HC.HashType = 0;
        for (counters.slice()) |entry|
            if (entry.count != 0) {
                if (hash > entry.hash) return error.Unsorted;
                hash = entry.hash;
            };

        for (keys) |key| try testing.expectEqual(@as(HC.CountType, 1), counters.get(.{key}));
    }
}
