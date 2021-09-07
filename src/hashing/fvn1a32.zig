pub const init_offset: u32 = 0x811c9dc5;
const prime: u32 = 0x01000193;

pub fn hash(offset: u32, comptime T: type, input: []const T, comptime len: u32) u32 {
    var value = offset;
    comptime var i: u32 = 0;
    inline while (i < len) : (i += 1) {
        value ^= input[i];
        value *%= prime;
    }
    return value;
}

const testing = @import("std").testing;
test "fnv1a32" {
    try testing.expect(hash(init_offset, u8, "", 0) == 0x811c9dc5);
    try testing.expect(hash(init_offset, u8, "a", 1) == 0xe40c292c);
    try testing.expect(hash(init_offset, u8, "foobar", 6) == 0xbf9cf968);
}
