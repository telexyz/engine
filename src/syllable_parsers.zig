const syllable_data_structs = @import("./syllable_data_structs.zig");
pub const Syllable = syllable_data_structs.Syllable;
const AmDau = syllable_data_structs.AmDau;
const AmGiua = syllable_data_structs.AmGiua;
const AmCuoi = syllable_data_structs.AmCuoi;
const Tone = syllable_data_structs.Tone;

const U2ACharStream = @import("./telex_char_stream.zig").Utf8ToAsciiTelexCharStream;

// Functions can be used as values and are equivalent to pointers.
// This is like function inteface, any function that can take same input format
// and return same output format can pass through.
const print_op = fn (comptime fmt_str: []const u8, args: anytype) void;

// A parser that take a stream of utf-8 chars (u21) and a Syllable as input
// then it shift Syllable internal states when a new char come until
// the Syllable is saturated (cannot take more char)
pub fn pushCharsToSyllable(comptime print: print_op, stream: *U2ACharStream, syllable: *Syllable) void {
    if (stream.last_char == 0) return;

    var n: usize = 3;
    if (!syllable.am_dau.isSaturated()) {
        // 1. The left part of a Vietnamese syllable has 3 chars at most
        if (stream.len < n) n = stream.len;
        const part0 = stream.buffer[0..n];
        syllable.am_dau = _amDau(part0);
        print("am_dau: \"{s}\" => {s}\n", .{ part0, syllable.am_dau });
    }

    var am_dau_len = syllable.am_dau.len();
    if (syllable.am_dau == .ng and stream.len >= 3 and stream.buffer[2] == 'h')
        am_dau_len = 3;

    // Check if is there any chars left for other parts
    if (am_dau_len == stream.len) return;

    if (!syllable.am_giua.isSaturated()) {
        // 2. The middle part of a Vietnamese syllable has 4 chars at most
        n = am_dau_len + 4;
        if (stream.len < n) n = stream.len;

        const part1 = stream.buffer[am_dau_len..n];
        syllable.am_giua = _amGiua(part1);
        print("am_giua: \"{s}\" => {s}\n", .{ part1, syllable.am_giua });
    }

    if (syllable.am_giua.len() == 0) {
        print("!!! VIOLATE: am_giua luôn phải có\n ", .{});
        syllable.can_be_vietnamese = false;
        return;
    }

    // Now have am_giua to validate am_dau
    if (!validateAmDau(print, syllable.am_dau, syllable.am_giua)) {
        syllable.can_be_vietnamese = false;
        return;
    }

    n = am_dau_len + syllable.am_giua.len();
    // Handle missing char for bellowing auto-conversion
    // .uyee <= .uye, .iee <= .ie, .yee <= .ye, .uee <= .ue, .uwow <= "uwo"
    switch (syllable.am_giua) {
        .uyez => {
            const cc = stream.buffer[am_dau_len + 3];
            if (n > stream.len or (cc != 'e' and cc != 'z')) n -= 1;
        },
        .iez, .yez, .uez => {
            const cc = stream.buffer[am_dau_len + 2];
            if (n > stream.len or (cc != 'e' and cc != 'z')) n -= 1;
        },
        .uow => {
            if (n > stream.len or stream.buffer[am_dau_len + 3] != 'w') n -= 1;
        },
        else => {}, // do nothing
    }

    // 3. The third part of a Vietnamese syllable is am_cuoi + tone
    // and it has 3 chars at most. This part can be an empty string
    // There is no am_cuoi and neutral tone
    const part3 = stream.buffer[n..stream.len];
    // Not Vietnamese since the two last parts has 3 chars at most
    if (part3.len > n + 3) {
        print("!!! VIOLATE: remain part \"{s}\" have more than 3 chars.\n", .{part3});
        syllable.can_be_vietnamese = false;
        return;
    }

    if (part3.len == 0) {
        syllable.am_cuoi = AmCuoi._none;
        // Handle rare cased huơ, khuơ ... => hua, khua ...
        if (syllable.am_giua == .uow) syllable.am_giua = .ua;
    } else {
        syllable.am_cuoi = _amCuoi(part3);
    }
    print("am_cuoi: \"{s}\" => {s}\n", .{ part3, syllable.am_cuoi });

    if (!validateNguyenAm(print, syllable.am_dau, syllable.am_giua, syllable.am_cuoi) or
        !validateBanAmCuoiVan(print, syllable.am_dau, syllable.am_giua, syllable.am_cuoi))
    {
        syllable.can_be_vietnamese = false;
        return;
    }

    // 4. Tone is the pitch shape of the whole syllable
    n = stream.len - syllable.am_cuoi.len() - n; // part4.len
    var tone_char: u21 = 0;
    if (stream.tone != 0) {
        if (n > 0) {
            print("!!! VIOLATE: already has tone in vowels\n", .{});
            syllable.can_be_vietnamese = false;
            return;
        }
        tone_char = stream.tone;
    } else {
        if (n > 1) {
            print("!!! VIOLATE: tone part has more than one char\n", .{});
            syllable.can_be_vietnamese = false;
            return;
        } else if (n == 1) {
            tone_char = stream.last_char;
        }
    }

    switch (tone_char) {
        0 => syllable.tone = ._none,
        's' => syllable.tone = .s,
        'f' => syllable.tone = .f,
        'r' => syllable.tone = .r,
        'x' => syllable.tone = .x,
        'j' => syllable.tone = .j,
        else => {
            print("!!! VIOLATE: \"{s}{c}\" is not toneable\n", .{ stream.buffer[0..stream.len], stream.tone });
            syllable.can_be_vietnamese = false;
            return;
        },
    }

    print("tone: {s}\n", .{syllable.tone});

    // if (syllable.am_giua == .uo and syllable.tone != ._none) {
    //     print("'uo' viết ko dấu thì chỉ đi được với thanh _none. VD: tuong, tuoi\n", .{});
    //     syllable.can_be_vietnamese = false;
    //     return;
    // }

    if (syllable.am_cuoi.isStop() and !syllable.tone.isStop()) {
        print("!!! VIOLATE: tone \"{s}\" cannot follow \"c,ch,t,p\".\n", .{syllable.tone});
        syllable.can_be_vietnamese = false;
        return;
    }

    syllable.can_be_vietnamese = true;
}

// Testing

const std = @import("std");
const expect = std.testing.expect;

test "pushCharsToSyllable()" {
    var char_stream = U2ACharStream.new();
    var syllable = Syllable.new();

    try char_stream.push('n');
    pushCharsToSyllable(printNothing, &char_stream, &syllable);
    try expect(syllable.am_dau == .n);
    try expect(syllable.isSaturated() == false);

    try char_stream.push('g');
    pushCharsToSyllable(printNothing, &char_stream, &syllable);
    try expect(syllable.am_dau == .ng);
    try expect(syllable.isSaturated() == false);

    try char_stream.push('h');
    pushCharsToSyllable(printNothing, &char_stream, &syllable);
    try expect(syllable.am_dau == .ng);
    try expect(syllable.isSaturated() == false);

    try char_stream.push('ế');
    try expect(char_stream.tone == 's');
    pushCharsToSyllable(printNothing, &char_stream, &syllable);
    try expect(syllable.am_dau == .ng);
    try expect(syllable.am_giua == .ez);
    try expect(syllable.tone == .s);
    try expect(syllable.isSaturated() == false);

    try char_stream.push('t');
    pushCharsToSyllable(printNothing, &char_stream, &syllable);
    try expect(syllable.am_dau == .ng);
    try expect(syllable.am_giua == .ez);
    try expect(syllable.am_cuoi == .t);
    try expect(syllable.tone == .s);

    try expect(syllable.am_dau.isSaturated() == true);
    try expect(syllable.am_giua.isSaturated() == true);
    try expect(syllable.am_cuoi.isSaturated() == true);
    try expect(syllable.tone.isSaturated() == true);
    try expect(syllable.isSaturated() == true);
}

const unicode = std.unicode;

/// A parser that take any utf-8 or ascii-telex string as input
/// and output a Syllable struct
// Syllable is a data structure that split am_tiet input into:
// .am_dau, .am_giua, .am_cuoi, and .tone enums. It also do a checking to see
// if this am_tiet .can_be_vietnamese or not
pub fn parseAmTietToGetSyllable(strict: bool, comptime print: print_op, str: []const u8) Syllable {
    var char_stream = U2ACharStream.new();
    char_stream.strict_mode = strict;
    return parseTokenToGetSyllable(strict, print, &char_stream, str);
}

pub fn parseTokenToGetSyllable(
    strict: bool,
    comptime print: print_op,
    char_stream: *U2ACharStream,
    str: []const u8,
) Syllable {
    var syllable = Syllable.new();
    var index: usize = 0;
    var next_index: usize = undefined;

    var byte: u8 = undefined;
    var char: u21 = undefined;
    var char_bytes_length: u3 = undefined;

    while (index < str.len) {
        byte = str[index];

        char_bytes_length = unicode.utf8ByteSequenceLength(byte) catch 0;
        // Error, just return syllable
        if (char_bytes_length == 0) return syllable;

        next_index = index + char_bytes_length;
        if (char_bytes_length > 1) {
            // Error, just return syllable
            if (next_index > str.len) return syllable;

            char = unicode.utf8Decode(str[index..next_index]) catch 0;

            // Error, just return syllable
            if (char == 0) return syllable;
        } else {
            char = @intCast(u21, byte);
        }

        char_stream.pushCharAndFirstByte(char, byte) catch {
            // Any error with char_stream, just return current parsed syllable
            // The error should not affect the result of the parse
            syllable.can_be_vietnamese = false;
            return syllable;
        };
        pushCharsToSyllable(print, char_stream, &syllable);
        index = next_index;
    }

    if (strict) {
        // Check #1: Filter out ascii-telex syllable like:
        // car => cả, beer => bể ...
        if (char_stream.tone == 0 and syllable.tone != ._none) {
            print("Don't accept ascii tone: car => cả, beer => bể ...\n", .{});
            syllable.can_be_vietnamese = false;
            return syllable;
        }

        // Check #2: Filter out ascii-telex syllable like:
        // awn => ăn, doo => dô
        if (syllable.hasMark() and !char_stream.has_mark) {
            // Ngoại trừ tự bỏ dấu của những âm tiết chắc chắn 99% là tiếng việt
            switch (syllable.am_giua) {
                .uyez => { // 99% nguyen => nguyên
                    return syllable;
                },
                .iez, .yez, .uez => { // nghieng => nghiêng
                    var score: u8 = if (char_stream.tone == 0) 0 else 2;
                    score += syllable.am_dau.len(); // max +2
                    score += syllable.am_cuoi.len(); // max +2
                    if (score >= 4) return syllable;
                },
                else => {},
            }
            print("??? Don't accept ascii mark: awn => ăn, doo => dô\n", .{});
            syllable.can_be_vietnamese = false;
            return syllable;
        }

        // Check #3: Filter out suffix look like syllable but it's not:
        // Mộtd, cuốiiii ...
        if (char_stream.len > syllable.len()) {
            if (syllable.am_giua == .ua and
                char_stream.buffer[char_stream.len - 3] == 'u' and
                char_stream.buffer[char_stream.len - 2] == 'o' and
                char_stream.buffer[char_stream.len - 1] == 'w') return syllable;
            print("??? Don't accept redundant suffix: Mộtd, cuốiiii ...\n", .{});
            // print("{s} => {}\n", .{ char_stream.buffer[0..char_stream.len], syllable });
            syllable.can_be_vietnamese = false;
            return syllable;
        }

        // Check #4: not .uo ko dấu thanh
        // if (syllable.am_giua == .uo) {
        //     print("!!! Don't accept .uo ko dấu thanh\n", .{});
        //     syllable.can_be_vietnamese = false;
        //     return syllable;
        // }
    }

    return syllable;
}

fn validateAmDau(comptime print: print_op, am_dau: AmDau, am_giua: AmGiua) bool {
    if (am_dau == .gi) {
        // TODO: Tìm thấy từ Gioóc (có thể là tên riêng) trong corpus
        // => Có nên coi nó là vn syllable ko? Tạm thời bỏ qua luật dưới để coi nó là TV
        if (am_giua.hasAmDem() and am_giua != .oaw and am_giua != .ooo) {
            print("!!! VIOLATE: am_dau 'gi' không đi cùng âm đệm u,o trừ trường hợp gioăng, Gioóc\n", .{});
            return false;
        }
        if (am_giua.startWithIY()) {
            print("!!! VIOLATE: am_dau 'gi' không đi nguyên âm bắt đầu bằng 'i', 'y'\n ", .{});
            return false;
        }
    }
    return true;
}

// - 2 bán âm cuối vần : i (y), u (o)
fn validateBanAmCuoiVan(comptime print: print_op, am_dau: AmDau, am_giua: AmGiua, am_cuoi: AmCuoi) bool {
    switch (am_cuoi) {
        .o, .u, .i, .y => {},
        else => {
            return true;
        },
    }
    // must be .o, .u, .i, .y  to continue to this step
    switch (am_giua) {
        .e, .oe => if (am_cuoi != .o) {
            print("!!! VIOLATE: 'e', 'oe' chỉ đi với bán âm cuối vần 'o'", .{});
            return false;
        },
        .i, .ez, .iez, .uy, .yez => if (am_cuoi != .u) {
            print("!!! VIOLATE: 'i', 'ê', 'iê', 'uy', 'yê' chỉ đi với bán âm cuối vần 'u'", .{});
            return false;
        },
        .o, .ow, .oz => if (am_cuoi != .i) {
            print("!!! VIOLATE: 'o', 'ơ', 'ô' chỉ đi với bán âm cuối vần 'i'", .{});
            return false;
        },
        .y, .aw, .ia, .ooo, .ua, .uez, .uaw, .uya, .uyez => if (am_cuoi != ._none) {
            if (am_dau == .qu and am_giua == .y and am_cuoi == .u) return true; // ngoài quýu
            if (am_dau == .kh and am_giua == .uez and am_cuoi == .u) return true; // ngoài khuều
            // print("!!! VIOLATE: 'uê' chỉ đi với bán âm cuối vần 'u'", .{});
            print("!!! VIOLATE: 'y', 'ă', 'ia', 'oo', 'ua', 'oă', 'uơ', 'ưa', 'uya', 'uyê' ko đi với bán âm cuối vần nào hết", .{});
            return false;
        },
        .u, .uoz => if (am_cuoi != .i) {
            print("!!! VIOLATE: 'u', 'uô' chỉ đi với bán âm cuối vần 'i'", .{});
            return false;
        },
        .oa => if (am_cuoi == .u) {
            print("!!! VIOLATE: 'oa' ko đi với bán âm cuối vần 'u'", .{});
            return false;
        },
        .uw, .uow => if (am_cuoi != .i and am_cuoi != .u) {
            print("!!! VIOLATE: 'ư', 'ươ' chỉ đi với bán âm cuối vần 'i', 'u'", .{});
            return false;
        },
        .uaz => if (am_cuoi != .y) {
            print("!!! VIOLATE: 'uâ' chỉ đi với bán âm cuối vần 'y'", .{});
            return false;
        },
        else => {
            return true;
        },
    }
    return true;
}

fn validateNguyenAm(comptime print: print_op, am_dau: AmDau, am_giua: AmGiua, am_cuoi: AmCuoi) bool {
    if (am_giua == .y and am_dau != .qu and am_cuoi != ._none) {
        print("!!! VIOLATE: 'y' trước không có 'qu' thì sau không có âm cuối. VD: tý", .{});
        return false;
    }

    // Trường hợp âm chính là nguyên âm đôi
    if (am_giua == .ia and am_cuoi != ._none) {
        print("!!! VIOLATE: 'ia' trước không có âm đệm, sau không có âm cuối. VD: tia, ỉa", .{});
        return false;
    }

    if (am_giua == .uyez and (am_cuoi == ._none)) {
        print("!!! VIOLATE: 'uyê' sau có âm cuối. VD: chuyên\n", .{});
        return false;
    }

    if (am_giua == .yez and ((am_dau != ._none and am_dau != .qu) or am_cuoi == ._none)) {
        print("!!! VIOLATE: 'yê' trước ko có hoặc chỉ đi với 'qu', sau có âm cuối. VD: yêu, quyên\n", .{});
        // 'qu' là sự kết hợp của 'q' và âm đệm 'u' nhằm giảm số lượng mã phải lưu.
        // Tương tự như 'uyee' ... ta ko lưu âm đệm 'u', 'o' mà kết hợp nó với
        // âm đầu hoặc nguyên âm để giảm số lượng mã phải lưu trữ.
        return false;
    }

    // {ya} trước có âm đệm, sau không có âm cuối. VD: khu{ya}
    if (am_giua == .uya and am_cuoi != ._none) {
        print("!!! VIOLATE: 'uya' sau ko có âm cuối. VD: khuya\n", .{});
        return false;
    }

    // if (am_giua == .iez and (am_dau == ._none or am_cuoi == ._none)) {
    //     if (am_cuoi == .c) return true; // ngoại trừ iếc
    //     print("!!! VIOLATE: 'iê' trước có âm đầu, sau có âm cuối, ngoại trừ iếc. VD: tiên\n", .{});
    //     return false;
    // }

    if (am_giua == .iez and (am_dau == ._none and am_cuoi == ._none)) {
        if (am_cuoi == .c) return true; // ngoại trừ iếc
        print("!!! VIOLATE: 'iê' trước có âm đầu hoặc sau có âm cuối\n", .{});
        return false;
    }

    if (am_giua == .uow and am_cuoi == ._none) {
        print("!!! VIOLATE: 'ươ' sau có âm cuối. VD: mượn\n", .{});
        return false;
    }

    if (am_giua == .uaw and am_cuoi != ._none) {
        print("!!! VIOLATE: 'ưa' sau không có âm cuối. VD: ưa\n", .{});
        return false;
    }

    if (am_giua == .uoz and am_cuoi == ._none) {
        print("!!! VIOLATE: 'uô' sau có âm cuối. VD: muốn\n", .{});
        return false;
    }

    if (am_giua == .ua and am_cuoi != ._none) {
        print("!!! VIOLATE: 'ua' sau không có âm cuối. VD: mua\n", .{});
        return false;
    }

    return true;
}

inline fn _amCuoi(str: []const u8) AmCuoi {
    const c0 = str[0];
    const c1 = if (str.len > 1) str[1] else 0;
    return switch (c0) {
        'n' => switch (c1) {
            'h' => AmCuoi.nh,
            'g' => .ng,
            else => .n,
        },
        'c' => if (c1 == 'h') AmCuoi.ch else .c,
        't' => .t,
        'p' => .p,
        'm' => .m,
        'i' => .i,
        'y' => .y,
        'u' => .u,
        'o' => .o,
        else => ._none,
    };
}

inline fn _amGiua(str: []const u8) AmGiua {
    const c0 = str[0];
    const c1 = if (str.len > 1) str[1] else 0;
    const c2 = if (str.len > 2) str[2] else 0;
    // const c3 = if (str.len > 3) str[3] else 0;

    return switch (c0) {
        'u' => switch (c1) { // u|uw|uwa|uwow|ua|uaa|uee|uy|uyee|uya|uoo
            'a' => switch (c2) {
                'a', 'z' => AmGiua.uaz, // uaa quan,quân
                'w' => .oaw, // auto correct .oaw <= uaw
                else => .ua, // ua
            },
            // 'e' => if (c2 == 'e') AmGiua.uez else .ue, // ue|uee quen,quên
            'e' => AmGiua.uez, // ue{e} => uez
            'w' => switch (c2) {
                'a' => AmGiua.uaw,
                'o' => .uow, // uwo{w} => uow, handle uwow len in parser
                else => .uw, // not uwow|uwa => uw
            },
            'o' => switch (c2) {
                'o' => AmGiua.uoz,
                'z' => .uoz,
                'w' => .uow, // tuơm, => tươm, thuở => thủa ??
                else => .u, // uoo|uow|uo ('uo' is no-mark)
            },
            'y' => switch (c2) { // uy|uya|uye|uyee|uyez
                'a' => AmGiua.uya,
                'e' => .uyez, // uye{e} => uyez
                else => .uy,
            },
            else => .u, // u
        },
        'o' => switch (c1) { // o|oo|ooo|ow|oe|oa|oaw
            'o' => AmGiua.ooo, // boong
            'z' => .oz,
            'w' => .ow,
            'e' => .oe,
            'a' => switch (c2) { // oa|oaw
                'z' => AmGiua.uaz, // tự động chữa lỗi oaz => uaz
                'w' => AmGiua.oaw,
                else => .oa,
            },
            else => .o,
        },
        'i' => switch (c1) { // i|ia|ie|iee|iez
            'a' => AmGiua.ia,
            'e' => .iez, // ie{e} => iez
            else => .i,
        },
        'y' => if (c1 == 'e') AmGiua.yez else .y, // y|ye{e}
        'e' => if (c1 == 'e' or c1 == 'z') AmGiua.ez else .e, // e|ee|ez
        'a' => switch (c1) { // a|aa|aw
            'a' => AmGiua.az,
            'z' => AmGiua.az,
            'w' => .aw,
            else => .a,
        },
        else => ._none,
    };
}

inline fn _amDau(str: []const u8) AmDau {
    const c0 = str[0];
    const c1 = if (str.len > 1) str[1] else 0;
    const c2 = if (str.len > 2) str[2] else 0;

    return switch (c0) {
        'b' => .b,
        'h' => .h,
        'l' => .l,
        'm' => .m,
        'r' => .r,
        's' => .s,
        'v' => .v,
        'x' => .x,

        'q' => if (c1 == 'u') AmDau.qu else ._none, // qu

        'c' => if (c1 == 'h') AmDau.ch else .c, // c|ch

        'd' => if (c1 == 'd') AmDau.zd else .d, // d|dd

        'z' => if (c1 == 'd') AmDau.zd else ._none,

        'g' => switch (c1) {
            // g|gh|gi, "gi" nếu sau có nguyên âm
            'h' => AmDau.gh,
            'i' => switch (c2) {
                'e', 'y', 'u', 'i', 'o', 'a' => AmDau.gi,
                else => .g,
            },
            else => .g,
        },

        'k' => if (c1 == 'h') AmDau.kh else .c, // k|kh

        'n' => switch (c1) { // n|nh|ng|ngh => ng
            'h' => AmDau.nh,
            'g' => .ng,
            else => .n,
        },

        'p' => if (c1 == 'h') AmDau.ph else .p, // p|ph

        't' => switch (c1) { // t|tr|th
            'r' => AmDau.tr,
            'h' => .th,
            else => .t,
        },
        else => ._none,
    };
}

fn canBeVietnamese(am_tiet: []const u8) bool {
    // return parseAmTietToGetSyllable(false, std.debug.print, am_tiet).can_be_vietnamese;
    return parseAmTietToGetSyllable(false, printNothing, am_tiet).can_be_vietnamese;
}

fn printNothing(comptime fmt_str: []const u8, args: anytype) void {
    // if (true)
    if (false)
        std.debug.print(fmt_str, args);
}

pub export fn testPerformance(n: usize) void {
    var i: usize = 0;
    while (i < n) : (i += 1) {
        _ = parseAmTietToGetSyllable(false, printNothing, "gioaj");
        _ = parseAmTietToGetSyllable(false, printNothing, "gioas");
        _ = parseAmTietToGetSyllable(false, printNothing, "giueej");
        _ = parseAmTietToGetSyllable(false, printNothing, "giuyeen");
        _ = parseAmTietToGetSyllable(false, printNothing, "giuyeetj");
        _ = parseAmTietToGetSyllable(false, printNothing, "giuy");
    }
}

test "canBeVietnamese() // get tone from stream" {
    try expect(canBeVietnamese("quyậts") == false);
}

test "canBeVietnamese() // other encode" {
    var syllable = parseAmTietToGetSyllable(false, printNothing, "mất");
    try expect(syllable.can_be_vietnamese);
    try expect(syllable.am_dau == .m);
    try expect(syllable.am_giua == .az);
    try expect(syllable.am_cuoi == .t);
    try expect(syllable.tone == .s);

    syllable = parseAmTietToGetSyllable(false, printNothing, "ắn");
    try expect(syllable.am_giua == .aw);
}

test "canBeVietnamese() positive fb_comments_10m" {
    const words_str = "TƯ trực trở giữ VỚI cực";
    var it = std.mem.split(u8, words_str, " ");
    while (it.next()) |word| {
        // std.debug.print("fb_comments_10m: {s}\n", .{word});
        try expect(canBeVietnamese(word));
    }
}

test "canBeVietnamese()" {
    try expect(canBeVietnamese("huơ") == true);
    try expect(canBeVietnamese("quýt") == true);
    try expect(canBeVietnamese("quýu") == true);
    try expect(canBeVietnamese("nghộ") == true);
    try expect(canBeVietnamese("Soọc") == true);
    try expect(canBeVietnamese("CÉCI") == false);
    try expect(canBeVietnamese("quyật") == false); // => quật
    try expect(canBeVietnamese("Gioăng") == true);
    try expect(canBeVietnamese("iệp") == true);
    try expect(canBeVietnamese("GII") == false);
    try expect(canBeVietnamese("Lyn") == false);
    try expect(canBeVietnamese("BÙI") == true);
    try expect(canBeVietnamese("que") == true);
    try expect(canBeVietnamese("nghe") == true);
    try expect(canBeVietnamese("binh") == true);
    try expect(canBeVietnamese("muoons") == true);
    try expect(canBeVietnamese("hoon") == true);
    try expect(canBeVietnamese("cuoocj") == true);
    try expect(canBeVietnamese("cawtx") == false);
    try expect(canBeVietnamese("nguyee") == false);
    try expect(canBeVietnamese("nguyeen") == true);
    try expect(canBeVietnamese("cuar") == true);
    try expect(canBeVietnamese("huyeets") == true);
    try expect(canBeVietnamese("huyeet") == false);
    try expect(canBeVietnamese("boong") == true);
    try expect(canBeVietnamese("nieemf") == true);
    try expect(canBeVietnamese("ieemf") == true);
    try expect(canBeVietnamese("ieef") == false);
    try expect(canBeVietnamese("yeeu") == true);
    try expect(canBeVietnamese("yee") == false);
    try expect(canBeVietnamese("tyeeu") == false);
    try expect(canBeVietnamese("iar") == true);
    try expect(canBeVietnamese("iamr") == false);
}

test "canBeVietnamese() // Edge cases" {
    try expect(canBeVietnamese("1triệu") == false);
    try expect(canBeVietnamese("GX") == false);
    try expect(canBeVietnamese("OOÒO") == false);
    try expect(canBeVietnamese("o") == true);
    try expect(canBeVietnamese("n") == false);
    try expect(canBeVietnamese("nnnn") == false);
    try expect(canBeVietnamese("") == false);
}

// test "canBeVietnamese() // am_dau gi ko di cung am dem u, o" {
//     try expect(canBeVietnamese("gioaj") == false);
//     try expect(canBeVietnamese("gioas") == false);
//     try expect(canBeVietnamese("giueej") == false);
//     try expect(canBeVietnamese("giuyeen") == false);
//     try expect(canBeVietnamese("giuyeetj") == false);
//     try expect(canBeVietnamese("giuy") == false);
// }

test "canBeVietnamese() // Weird cases" {
    // Tiếng đồng bào: Đắk Lắk, Niê, Cơtu
    // Từ mượn: ôtô, căngtin, đôla, Ôliu, côngtơ, bêtông

    try expect(canBeVietnamese("gioocs"));

    // 'gi' and 'd' are the same initial part
    // 'g' and 'd' are different
    // => 'gieets' is sort for 'giiets'
    try expect(canBeVietnamese("gieets") == true);
    try expect(canBeVietnamese("dieets") == true);
}

test "canBeVietnamese() // No-tone and/or no-mark" {
    try expect(canBeVietnamese("vuong") == false); // nhập nhằng: k biết là vuông hay vương
    try expect(canBeVietnamese("chuong") == false); // k biết là chương hay chuông
    try expect(canBeVietnamese("tuoij") == false);
    try expect(canBeVietnamese("chos") == true);
    try expect(canBeVietnamese("ox") == true);
}

fn strToAmTiet(str: []const u8) []const u8 {
    var buffer: [11]u8 = undefined;
    const buff = buffer[0..];
    var syll = parseAmTietToGetSyllable(false, printNothing, str);
    return syll.printBuffTelex(buff);
}

fn utf8ToAmTiet(str: []const u8) []const u8 {
    // return syllableToAmTiet(parseAmTietToGetSyllable(true, printNothing, str));
    var buffer: [11]u8 = undefined;
    const buff = buffer[0..];
    return parseAmTietToGetSyllable(true, printNothing, str).printBuffTelex(buff);
}

test "iee, yee (uyee), ooo, uee, uaz <= oaz" {
    // Note: Need to convert no-mark format back to marked version for
    // following vowels:
    // .iee <= .ie,
    // .yee <= .ye,
    // .uyee <= .uye,
    // .uee <= .ue,
    // .uaz <= oaz
    // the user is aiming for 'ô' or 'oo' (both need to type double 'o')
    try std.testing.expectEqualStrings(utf8ToAmTiet("tuơ"), "tua");
    try std.testing.expectEqualStrings(utf8ToAmTiet("ngoẩy"), "nguaayr");
    try std.testing.expectEqualStrings(utf8ToAmTiet("toong"), "tooong");
    try std.testing.expectEqualStrings(utf8ToAmTiet("thoọng"), "thooongj");
    try std.testing.expectEqualStrings(utf8ToAmTiet("đoong"), "ddooong");

    try std.testing.expectEqualStrings(utf8ToAmTiet("voọc"), "vooocj");
    try std.testing.expectEqualStrings(strToAmTiet("tieu"), "tieeu");
    try std.testing.expectEqualStrings(strToAmTiet("yeu"), "yeeu");
    try std.testing.expectEqualStrings(strToAmTiet("tuyenr"), "tuyeenr");
    try std.testing.expectEqualStrings(strToAmTiet("tuej"), "tueej");
}

test "..." {
    try std.testing.expectEqualStrings(utf8ToAmTiet("BÔI"), "booi");
    try std.testing.expectEqualStrings(utf8ToAmTiet("BIÊN"), "bieen");
    try std.testing.expectEqualStrings(utf8ToAmTiet("CHUẨN"), "chuaanr");
    // try std.testing.expectEqualStrings(utf8ToAmTiet(""), "");
}

test "canBeVietnamese() // Auto-repair obvious cases" {
    try expect(canBeVietnamese("sưòn")); // sườn
    try expect(canBeVietnamese("suờn")); // sườn
    try expect(canBeVietnamese("tuơ")); // tua
    try expect(canBeVietnamese("tuơm")); // tươm
    try expect(canBeVietnamese("tiem")); // tiêm
    try expect(canBeVietnamese("tiém")); // tiếm
    try expect(canBeVietnamese("tuyen")); // tuyên
    try expect(canBeVietnamese("cuă")); // cưa
    try expect(canBeVietnamese("cưă")); // cưa
}

// - - -

fn canBeVietnameseStrict(am_tiet: []const u8) bool {
    // return parseAmTietToGetSyllable(true, std.debug.print, am_tiet).can_be_vietnamese;
    return parseAmTietToGetSyllable(true, printNothing, am_tiet).can_be_vietnamese;
}

test "canBeVietnamese() // alphamarks exceptions" {
    // try expect(canBeVietnameseStrict(""));

    try expect(canBeVietnameseStrict("Quấc"));
    // Gốc là Quấc, do phổ cập Quấc ngữ nên chỉnh lại là Quốc cho dân ta dễ viết

    try expect(canBeVietnameseStrict("quạu"));
    try expect(canBeVietnameseStrict("quọ"));
    try expect(canBeVietnameseStrict("tuon") == false);
    try expect(canBeVietnameseStrict("iến"));
    try expect(canBeVietnameseStrict("iếc")); // trong yêu iếc
    try expect(canBeVietnameseStrict("miéng"));
    try expect(canBeVietnameseStrict("Nguyen"));
    try expect(canBeVietnameseStrict("nghieng"));
    try expect(canBeVietnameseStrict("khuắng"));
    try expect(canBeVietnameseStrict("khuều"));
    try expect(canBeVietnameseStrict("ngoẩy"));
    try expect(canBeVietnameseStrict("ðạo"));
    try expect(canBeVietnameseStrict("Ðạo"));
    try expect(canBeVietnameseStrict("nội"));
}
