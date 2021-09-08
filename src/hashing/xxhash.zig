const std = @import("std");
const mem = std.mem;
const math = std.math;
const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;

pub const XXHash32 = XXHash(XH32);

const XH32 = struct {
    pub const block_length = 16;
    pub const Int = u32;

    const primes = [5]u32{
        0x9e3779b1,
        0x85ebca77,
        0xc2b2ae3d,
        0x27d4eb2f,
        0x165667b1,
    };

    acc1: u32,
    acc2: u32,
    acc3: u32,
    acc4: u32,
    msg_len: u64 = 0,

    inline fn mix0(acc: u32, lane: u32) u32 {
        return math.rotl(u32, acc +% lane *% primes[1], 13) *% primes[0];
    }

    inline fn mix32(acc: u32, lane: u32) u32 {
        return math.rotl(u32, acc +% lane *% primes[2], 17) *% primes[3];
    }

    inline fn mix8(acc: u32, lane: u8) u32 {
        return math.rotl(u32, acc +% lane *% primes[4], 11) *% primes[0];
    }

    pub fn init(seed: u32) XH32 {
        return XH32{
            .acc1 = seed +% primes[0] +% primes[1],
            .acc2 = seed +% primes[1],
            .acc3 = seed,
            .acc4 = seed -% primes[0],
        };
    }

    pub fn update(self: *XH32, b: []const u8) void {
        assert(b.len % 16 == 0);

        var off: usize = 0;
        while (off < b.len) : (off += 16)
            @call(.{ .modifier = .always_inline }, self.round, .{b[off..][0..16]});

        self.msg_len += b.len;
    }

    fn round(self: *XH32, b: *const [16]u8) void {
        self.acc1 = mix0(self.acc1, mem.readIntLittle(u32, b[00..04]));
        self.acc2 = mix0(self.acc2, mem.readIntLittle(u32, b[04..08]));
        self.acc3 = mix0(self.acc3, mem.readIntLittle(u32, b[08..12]));
        self.acc4 = mix0(self.acc4, mem.readIntLittle(u32, b[12..16]));
    }

    pub fn final(self: *XH32, b: []const u8) u32 {
        assert(b.len < 16);

        var acc = if (self.msg_len < 16)
            self.acc3 +% primes[4]
        else
            math.rotl(u32, self.acc1, 01) +%
                math.rotl(u32, self.acc2, 07) +%
                math.rotl(u32, self.acc3, 12) +%
                math.rotl(u32, self.acc4, 18);
        acc +%= @truncate(u32, self.msg_len +% b.len);

        switch (@intCast(u4, b.len)) {
            0 => {},
            1 => {
                acc = mix8(acc, b[0]);
            },
            2 => {
                acc = mix8(acc, b[0]);
                acc = mix8(acc, b[1]);
            },
            3 => {
                acc = mix8(acc, b[0]);
                acc = mix8(acc, b[1]);
                acc = mix8(acc, b[2]);
            },
            4 => {
                const num = mem.readIntLittle(u32, b[0..4]);
                acc = mix32(acc, num);
            },
            5 => {
                const num = mem.readIntLittle(u32, b[0..4]);
                acc = mix32(acc, num);
                acc = mix8(acc, b[4]);
            },
            6 => {
                const num = mem.readIntLittle(u32, b[0..4]);
                acc = mix32(acc, num);
                acc = mix8(acc, b[4]);
                acc = mix8(acc, b[5]);
            },
            7 => {
                const num = mem.readIntLittle(u32, b[0..4]);
                acc = mix32(acc, num);
                acc = mix8(acc, b[4]);
                acc = mix8(acc, b[5]);
                acc = mix8(acc, b[6]);
            },
            8 => {
                const num1 = mem.readIntLittle(u32, b[0..4]);
                const num2 = mem.readIntLittle(u32, b[4..8]);
                acc = mix32(acc, num1);
                acc = mix32(acc, num2);
            },
            9 => {
                const num1 = mem.readIntLittle(u32, b[0..4]);
                const num2 = mem.readIntLittle(u32, b[4..8]);
                acc = mix32(acc, num1);
                acc = mix32(acc, num2);
                acc = mix8(acc, b[8]);
            },
            10 => {
                const num1 = mem.readIntLittle(u32, b[0..4]);
                const num2 = mem.readIntLittle(u32, b[4..8]);
                acc = mix32(acc, num1);
                acc = mix32(acc, num2);
                acc = mix8(acc, b[8]);
                acc = mix8(acc, b[9]);
            },
            11 => {
                const num1 = mem.readIntLittle(u32, b[0..4]);
                const num2 = mem.readIntLittle(u32, b[4..8]);
                acc = mix32(acc, num1);
                acc = mix32(acc, num2);
                acc = mix8(acc, b[8]);
                acc = mix8(acc, b[9]);
                acc = mix8(acc, b[10]);
            },
            12 => {
                const num1 = mem.readIntLittle(u32, b[0..4]);
                const num2 = mem.readIntLittle(u32, b[4..8]);
                const num3 = mem.readIntLittle(u32, b[8..12]);
                acc = mix32(acc, num1);
                acc = mix32(acc, num2);
                acc = mix32(acc, num3);
            },
            13 => {
                const num1 = mem.readIntLittle(u32, b[0..4]);
                const num2 = mem.readIntLittle(u32, b[4..8]);
                const num3 = mem.readIntLittle(u32, b[8..12]);
                acc = mix32(acc, num1);
                acc = mix32(acc, num2);
                acc = mix32(acc, num3);
                acc = mix8(acc, b[12]);
            },
            14 => {
                const num1 = mem.readIntLittle(u32, b[0..4]);
                const num2 = mem.readIntLittle(u32, b[4..8]);
                const num3 = mem.readIntLittle(u32, b[8..12]);
                acc = mix32(acc, num1);
                acc = mix32(acc, num2);
                acc = mix32(acc, num3);
                acc = mix8(acc, b[12]);
                acc = mix8(acc, b[13]);
            },
            15 => {
                const num1 = mem.readIntLittle(u32, b[0..4]);
                const num2 = mem.readIntLittle(u32, b[4..8]);
                const num3 = mem.readIntLittle(u32, b[8..12]);
                acc = mix32(acc, num1);
                acc = mix32(acc, num2);
                acc = mix32(acc, num3);
                acc = mix8(acc, b[12]);
                acc = mix8(acc, b[13]);
                acc = mix8(acc, b[14]);
            },
        }

        acc ^= acc >> 15;
        acc *%= primes[1];
        acc ^= acc >> 13;
        acc *%= primes[2];
        acc ^= acc >> 16;

        return acc;
    }
};

fn XXHash(comptime Impl: type) type {
    return struct {
        const Self = @This();

        pub const block_length = Impl.block_length;

        state: Impl,
        buf: [block_length]u8 = undefined,
        buf_len: u8 = 0,

        pub fn init(seed: Impl.Int) Self {
            return Self{ .state = Impl.init(seed) };
        }

        pub fn update(self: *Self, b: []const u8) void {
            var off: usize = 0;

            if (self.buf_len != 0 and self.buf_len + b.len >= block_length) {
                off += block_length - self.buf_len;
                mem.copy(u8, self.buf[self.buf_len..], b[0..off]);
                self.state.update(self.buf[0..]);
                self.buf_len = 0;
            }

            const remain_len = b.len - off;
            const aligned_len = remain_len - (remain_len % block_length);
            self.state.update(b[off .. off + aligned_len]);

            mem.copy(u8, self.buf[self.buf_len..], b[off + aligned_len ..]);
            self.buf_len += @intCast(u8, b[off + aligned_len ..].len);
        }

        pub fn final(self: *Self) Impl.Int {
            const rem_key = self.buf[0..self.buf_len];

            return self.state.final(rem_key);
        }

        pub fn hash(seed: Impl.Int, input: []const u8) Impl.Int {
            const aligned_len = input.len - (input.len % block_length);

            var c = Impl.init(seed);
            @call(.{ .modifier = .always_inline }, c.update, .{input[0..aligned_len]});
            return @call(.{ .modifier = .always_inline }, c.final, .{input[aligned_len..]});
        }
    };
}

const prime32: u32 = 2654435761;
const prime64: u64 = 11400714785074694797;

const test_buffer1 = blk: {
    @setEvalBranchQuota(3000);

    var bytegen: u64 = prime32;
    var buf: [2367]u8 = undefined;

    for (buf) |*c| {
        c.* = @truncate(u8, bytegen >> 56);
        bytegen *%= prime64;
    }

    break :blk buf;
};
const test_buffer2 = blk: {
    var buf: [100]u8 = undefined;
    for (buf) |*c, i| c.* = i;
    break :blk &buf;
};

const Test = struct {
    seed: u64,
    data: []const u8,
    sum: u64,

    fn new(seed: u64, data: []const u8, sum: u64) Test {
        return Test{ .seed = seed, .data = data, .sum = sum };
    }
};
const test_data32 = [_]Test{
    // From the reference C implementation
    Test.new(0, "", 0x02cc5d05),
    Test.new(prime32, "", 0x36b78ae7),
    Test.new(0, test_buffer1[0..1], 0xCF65B03E),
    Test.new(prime32, test_buffer1[0..1], 0xB4545AA4),
    Test.new(0, test_buffer1[0..14], 0x1208E7E2),
    Test.new(prime32, test_buffer1[0..14], 0x6AF1D1FE),
    Test.new(0, test_buffer1[0..222], 0x5BD11DBD),
    Test.new(prime32, test_buffer1[0..222], 0x58803C5F),
    // From the twox-hash rust crate
    Test.new(0, &[_]u8{42}, 0xe0fe705f),
    Test.new(0, "Hello, world!\x00", 0x9e5e7e93),
    Test.new(0, test_buffer2, 0x7f89ba44),
    Test.new(0x42c91977, "", 0xd6bf8459),
    Test.new(0x42c91977, test_buffer2, 0x6d2f6c17),
};
test "XXHash Test Vectors" {
    for (test_data32) |t| try expectEqual(t.sum, XXHash32.hash(@intCast(u32, t.seed), t.data));
}
