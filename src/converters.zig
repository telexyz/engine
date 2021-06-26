const std = @import("std");
const fmt = std.fmt;

const syllable_data_structs = @import("./syllable_data_structs.zig");
const Syllable = syllable_data_structs.Syllable;
const AmDau = syllable_data_structs.AmDau;
const AmGiua = syllable_data_structs.AmGiua;
const AmCuoi = syllable_data_structs.AmCuoi;
const Tone = syllable_data_structs.Tone;

const parseAmTietToGetSyllable = @import("./parsers.zig").parseAmTietToGetSyllable;

const AM_GIUA_BITS_OFFSET = 5;
const AM_CUOI_BITS_OFFSET = 10;
const TONE_BITS_OFFSET = 14;

fn print(comptime fmt_str: []const u8, args: anytype) void {
    // @import("std").debug.print(fmt_str, args);
}

// Convert any Syllable to an uniq id (17 bits)
pub fn syllableToId(syllable: Syllable) u17 {
    return
    // am_dau 0-27, 5-bits. Dư 4-slots => đánh dấu đc 4 * 32 * 16 * 8
    @intCast(u17, @enumToInt(syllable.am_dau)) |
        // am_giua 0-30, 5-bits. Dư 1-slot => đánh dấu đc 28 * 1 * 16 * 8
        (@intCast(u17, @enumToInt(syllable.am_giua)) << AM_GIUA_BITS_OFFSET) |
        // am_cuoi 0-12, 4-bits. Dư 3-slots => đánh dấu đc 28 * 31 * 3 * 8
        (@intCast(u17, @enumToInt(syllable.am_cuoi)) << AM_CUOI_BITS_OFFSET) |
        // tone 0-5, 3-bits. Dư 2 slots => đánh dấu đc 28 * 31 * 13 * 2
        (@intCast(u17, @enumToInt(syllable.tone)) << TONE_BITS_OFFSET);
}

// => Tổng slots còn dư để dùng việc khác là 63368 = 16384 + 3584 + 20832 + 22568

// Verify assumption:
// - - - - - - - - -
// Total slots 131072 = 2^17
// Used slots 67704 = 28*31*13*6
// Remain slots 63368 = 131072 - 67704. Ok! Good!

// Chỗ slot dư này có thể dùng để đánh dấu những từ có trong văn bản
// nhưng ko phải âm tiết tiếng Việt.

// u64 là kiểu dữ liệu phổ biến, dùng 64 bit có thể thể hiện được tri-syllable
// 64/3 = 21, 21-17 = 3, còn dư những 3-bits để làm việc khác:
// a. Dùng 1-bit để đánh dấu xem syllable có viết hoa chữ đầu tiên hay kox?
// b. Dùng 1-bit để đánh dấu từ này có phải tiếng Việt hay ko?
//   (ko phải thì lookup trong từ điển chẳng hạn)
// c. Còn dư 2-bits của Syllable (2=21-17-1-1) chưa biết làm gì?

// => Còn 1-bit dư của cả tri-syllable (1=64-21*3) chưa biết làm gì?

pub fn amTietToId(am_tiet: []const u8) u17 {
    return syllableToId(parseAmTietToGetSyllable(false, print, am_tiet));
}

// Convert an id to Syllable
fn idToSyllable(id: u17) Syllable {
    var syllable = Syllable.init();

    const n0 = @truncate(u5, id);
    syllable.am_dau = @intToEnum(AmDau, n0);

    const n1 = @truncate(u5, id >> AM_GIUA_BITS_OFFSET);
    syllable.am_giua = @intToEnum(AmGiua, n1);

    const n2 = @truncate(u4, id >> AM_CUOI_BITS_OFFSET);
    syllable.am_cuoi = @intToEnum(AmCuoi, n2);

    const n3 = @truncate(u3, id >> TONE_BITS_OFFSET);
    syllable.tone = @intToEnum(Tone, n3);

    return syllable;
}

pub fn syllableToAmTiet(syllable: Syllable) []const u8 {
    const am_dau_str = _noneOrName(AmDau, syllable.am_dau);
    const am_giua_str = _noneOrName(AmGiua, syllable.am_giua);
    const am_cuoi_str = _noneOrName(AmCuoi, syllable.am_cuoi);
    const tone_str = _noneOrName(Tone, syllable.tone);

    // Vietnamese syllable has at most 10 chars, + ending 0 = 11
    var all_together: [11]u8 = undefined;
    const all_together_slice = all_together[0..];

    const am_tiet = fmt.bufPrint(all_together_slice, "{s}{s}{s}{s}", .{ am_dau_str, am_giua_str, am_cuoi_str, tone_str }) catch unreachable;

    // print("\nsyllableToAmTiet: '{s}'\n\n", .{am_tiet});
    return am_tiet;
}

inline fn _noneOrName(comptime Enum: type, tag: Enum) []const u8 {
    return if (tag == Enum._none) "" else @tagName(tag);
}

pub fn idToAmTiet(id: u17) []const u8 {
    return syllableToAmTiet(idToSyllable(id));
}

pub fn syllableToNoMarkSyllable(syllable: Syllable) Syllable {
    return Syllable{
        .am_dau = syllable.am_dau.noMark(),
        .am_giua = syllable.am_giua.noMark(),
        .am_cuoi = syllable.am_cuoi,
        .tone = ._none,
        .can_be_vietnamese = true,
    };
}

pub fn amTietToNoMarkId(am_tiet: []const u8) u17 {
    const syllable = parseAmTietToGetSyllable(false, print, am_tiet);
    const no_mark_syllable = syllableToNoMarkSyllable(syllable);
    return syllableToId(no_mark_syllable);
}

// Testing purpose

fn amTietToNoMarkAmTiet(am_tiet: []const u8) []const u8 {
    return idToAmTiet(amTietToNoMarkId(am_tiet));
}

const testing = std.testing;
const expect = testing.expect;
const mem = std.mem;

const _a_id = (1 << AM_GIUA_BITS_OFFSET) + (0 << TONE_BITS_OFFSET);
const _acs_id = (1 << AM_GIUA_BITS_OFFSET) + (1 << AM_CUOI_BITS_OFFSET) + (1 << TONE_BITS_OFFSET);

test "amTietToId()" {
    try expect(amTietToId("a") == _a_id);
    try expect(amTietToId("acs") == _acs_id);
}

test "idToAmTiet()" {
    try expect(mem.eql(u8, idToAmTiet(_acs_id), "acs"));
    try expect(mem.eql(u8, idToAmTiet(amTietToId("đuyỄn")), "dduyeenx"));
    print("\n\nHERE HERE HERE\n{s}\n\n\n", .{idToAmTiet(amTietToId("cƯờNg"))});
    try expect(mem.eql(u8, idToAmTiet(amTietToId("cƯờNg")), "cuwowngf"));
    try expect(mem.eql(u8, idToAmTiet(amTietToId("Đoõng")), "ddoongx"));
}

test "amTietToNoMarkAmTiet()" {
    try expect(mem.eql(u8, amTietToNoMarkAmTiet("nguyeenx"), "nguyeen"));
    try expect(mem.eql(u8, amTietToNoMarkAmTiet("cuoocs"), "cuoc"));
    try expect(mem.eql(u8, amTietToNoMarkAmTiet("cuwowcj"), "cuoc"));
    try expect(mem.eql(u8, amTietToNoMarkAmTiet("booongx"), "booong"));
    try expect(mem.eql(u8, amTietToNoMarkAmTiet("boongs"), "bong"));
}

test "idToAmTiet(amTietToId()) // Auto-repair obvious cases" {
    try testing.expectEqualStrings(idToAmTiet(amTietToId("sưòn")), "suwownf");
    try testing.expectEqualStrings(idToAmTiet(amTietToId("suơn")), "suown");
    try testing.expectEqualStrings(idToAmTiet(amTietToId("niemj")), "nieemj");
    try testing.expectEqualStrings(idToAmTiet(amTietToId("hịem")), "hieemj");
    try testing.expectEqualStrings(idToAmTiet(amTietToId("tiẹm")), "tieemj");
    try testing.expectEqualStrings(idToAmTiet(amTietToId("huýen")), "huyeens");
    try testing.expectEqualStrings(idToAmTiet(amTietToId("ỹen")), "yeenx");
}
