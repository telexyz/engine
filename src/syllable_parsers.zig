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
    print("am_giua: \"{s}\"\n", .{syllable.am_giua});

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
        .iez, .uez => {
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

    // Auto-correct uaw => oaw
    // if (syllable.am_giua == .uaw and syllable.am_dau != ._none and syllable.am_cuoi != ._none) syllable.am_giua = .oaw;

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
    try expect(syllable.am_dau == .ngh);
    try expect(syllable.isSaturated() == false);

    try char_stream.push('ế');
    try expect(char_stream.tone == 's');
    pushCharsToSyllable(printNothing, &char_stream, &syllable);
    try expect(syllable.am_dau == .ngh);
    try expect(syllable.am_giua == .ez);
    try expect(syllable.tone == .s);
    try expect(syllable.isSaturated() == false);

    try char_stream.push('t');
    pushCharsToSyllable(printNothing, &char_stream, &syllable);
    try expect(syllable.am_dau == .ngh);
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

        char_stream.pushCharAndFirstByte(char, byte) catch |err| {
            // Any error with char_stream, just return current parsed syllable
            // The error should not affect the result of the parse
            print("char_stream error: {}", .{err});
            syllable.can_be_vietnamese = false;
            return syllable;
        };
        pushCharsToSyllable(print, char_stream, &syllable);
        index = next_index;
    }

    if (!syllable.can_be_vietnamese) return syllable;

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
            var good_enough = false;
            // Ngoại trừ tự bỏ dấu của những âm tiết chắc chắn 99% là tiếng việt
            switch (syllable.am_giua) {
                .uyez => { // 99% nguyen => nguyên
                    char_stream.has_mark = true;
                    good_enough = true;
                },
                .iez, .uez => { // nghieng => nghiêng
                    var score: u8 = if (char_stream.tone == 0) 0 else 2;
                    score += syllable.am_dau.len(); // max +2
                    score += syllable.am_cuoi.len(); // max +2
                    if (score >= 4) {
                        char_stream.has_mark = true;
                        good_enough = true;
                    }
                },
                else => {},
            }
            if (!good_enough) {
                print("??? Don't accept ascii mark: awn => ăn, doo => dô\n", .{});
                syllable.can_be_vietnamese = false;
                return syllable;
            }
        }

        // Check #3: Filter out suffix look like syllable but it's not:
        // Mộtd, cuốiiii ...
        if (char_stream.len > syllable.len()) {
            var good_enough = false;

            if (syllable.am_giua == .ua and
                char_stream.buffer[char_stream.len - 3] == 'u' and
                char_stream.buffer[char_stream.len - 2] == 'o' and
                char_stream.buffer[char_stream.len - 1] == 'w') good_enough = true;

            if (!good_enough) {
                print("??? Don't accept redundant suffix: Mộtd, cuốiiii ...\n", .{});
                syllable.can_be_vietnamese = false;
                return syllable;
            }
        }
    }

    if (syllable.can_be_vietnamese) syllable.normalize();
    return syllable;
}

fn validateAmDau(comptime print: print_op, am_dau: AmDau, am_giua: AmGiua) bool {
    if (am_dau == .gi) {
        // TODO: Tìm thấy từ Gioóc (có thể là tên riêng) trong corpus
        // => Có nên coi nó là vn syllable ko? Tạm thời bỏ qua luật dưới để coi nó là TV
        if (am_giua.hasAmDem() and am_giua != .oaw and am_giua != .ooo) {
            print("!!! VIOLATE: âm đầu 'gi' không đi cùng âm đệm u,o trừ trường hợp gioăng, Gioóc\n", .{});
            return false;
        }
        if (am_giua.startWithIY()) {
            print("!!! VIOLATE: âm đầu 'gi' không đi nguyên âm bắt đầu bằng 'i', 'y'\n ", .{});
            return false;
        }
    }

    if (am_dau == .c and (am_giua == .oa or am_giua == .oaw or am_giua == .oe)) {
        print("!!! VIOLATE: âm đầu 'c' không đi nguyên âm 'oa, oă, oe'\n ", .{});
        return false;
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
        .i, .ez, .iez, .uy => if (am_cuoi != .u) {
            print("!!! VIOLATE: 'i', 'ê', 'iê', 'uy', 'yê' chỉ đi với bán âm cuối vần 'u'\n", .{});
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
            print("!!! VIOLATE: 'y', 'ă', 'ia', 'oo', 'ua', 'oă', 'uơ', 'ưa', 'uya', 'uyê' không đi với bán âm cuối vần nào hết", .{});
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

    if (am_giua == .iez and am_cuoi == ._none) {
        print("!!! VIOLATE: 'iê/yê' sau có âm cuối. VD: yêu, quyên\n", .{});
        return false;
    }

    // {ya} trước có âm đệm, sau không có âm cuối. VD: khu{ya}
    if (am_giua == .uya and am_cuoi != ._none) {
        print("!!! VIOLATE: 'uya' sau ko có âm cuối. VD: khuya\n", .{});
        return false;
    }

    if (am_giua == .uyez and !(am_cuoi == .n or am_cuoi == .t)) {
        print("!!! VIOLATE: 'uyê' chỉ đi với `n, t`\n", .{});
        return false;
    }

    if (am_giua == .oa and am_cuoi == .u) {
        print("!!! VIOLATE: 'oa' không đi với `u`\n", .{});
        return false;
    }

    if ((am_giua == .ua or am_giua == .uaw) and am_cuoi != ._none) {
        print("!!! VIOLATE: 'ua, ưa' không đi với âm cuối\n", .{});
        return false;
    }

    if (am_giua == .ooo and !(am_cuoi == .ng or am_cuoi == .c)) {
        print("!!! VIOLATE: 'oo' chỉ đi với `ng, c`\n", .{});
        return false;
    }

    if (am_giua == .oaw) switch (am_cuoi) {
        .nh, .ch, .o, .u, .i, .y => {
            print("!!! VIOLATE: 'oă' không đi với `nh, ch, o, u, i, y`\n", .{});
            return false;
        },
        else => return true,
    };

    if (am_giua == .uez) switch (am_cuoi) {
        .ng, .c, .o, .i, .y => {
            print("!!! VIOLATE: 'uê' không đi với `ng, c, o, i, y`\n", .{});
            return false;
        },
        else => return true,
    };

    if (am_giua == .uaz) switch (am_cuoi) {
        .nh, .ch, .o, .u, .i => {
            print("!!! VIOLATE: 'uâ' không đi với `nh, ch, o, u, i`\n", .{});
            return false;
        },
        else => return true,
    };

    if (am_giua == .oe) switch (am_cuoi) {
        .nh, .ch, .u, .i, .y => {
            print("!!! VIOLATE: 'oe' không đi với `nh, ch, u, i, y`\n", .{});
            return false;
        },
        else => return true,
    };

    if (am_giua == .uy) switch (am_cuoi) {
        .m, .ng, .c, .o, .i, .y => {
            print("!!! VIOLATE: 'uy' không đi với `m, ng, c, o, i, y`\n", .{});
            return false;
        },
        else => return true,
    };

    if (am_giua == .aw) switch (am_cuoi) {
        .nh, .ch, .u, .o, .i, .y => {
            print("!!! VIOLATE: 'ă' không đi với `nh, ch, u, o, i, y`\n", .{});
            return false;
        },
        else => return true,
    };

    if (am_giua == .az) switch (am_cuoi) {
        .nh, .ch, .o, .i => {
            print("!!! VIOLATE: 'â' không đi với `nh, ch, o, i`\n", .{});
            return false;
        },
        else => return true,
    };

    if (am_giua == .u) switch (am_cuoi) {
        .nh, .ch, .o, .u => {
            print("!!! VIOLATE: 'u' không đi với `nh, ch, o, u`\n", .{});
            return false;
        },
        else => return true,
    };

    if (am_giua == .uw) switch (am_cuoi) {
        .nh, .ch, .y => {
            print("!!! VIOLATE: 'ư' không đi với `nh, ch, y`\n", .{});
            return false;
        },
        else => return true,
    };

    if (am_giua == .o) switch (am_cuoi) {
        .nh, .ch, .u, .o, .y => {
            print("!!! VIOLATE: 'o' không đi với `nh, ch, o, u, y`\n", .{});
            return false;
        },
        else => return true,
    };

    if (am_giua == .oz) switch (am_cuoi) {
        .nh, .ch, .u, .o, .y => {
            print("!!! VIOLATE: 'ô' không đi với `nh, ch, o, u, y`\n", .{});
            return false;
        },
        else => return true,
    };

    if (am_giua == .ow) switch (am_cuoi) {
        .nh, .ch, .u, .o, .y => {
            print("!!! VIOLATE: 'ơ' không đi với `nh, ch, o, u, y`\n", .{});
            return false;
        },
        else => return true,
    };

    if (am_giua == .iez and (am_dau == ._none and am_cuoi == ._none)) {
        if (am_cuoi == .c) return true; // ngoại trừ iếc
        print("!!! VIOLATE: 'iê' trước có âm đầu hoặc sau có âm cuối\n", .{});
        return false;
    }

    if (am_giua == .uow and am_cuoi == ._none) {
        print("!!! VIOLATE: 'ươ' sau có âm cuối. VD: mượn\n", .{});
        return false;
    }
    if (am_giua == .uow) switch (am_cuoi) {
        .ch, .nh, .o, .y => {
            print("!!! VIOLATE: 'ươ' không đi cùng `ch, nh, o, y`\n", .{});
            return false;
        },
        ._none => {
            print("!!! VIOLATE: 'ươ' sau có âm cuối. VD: mượn\n", .{});
            return false;
        },
        else => {
            return true;
        },
    };

    if (am_giua == .uaw and am_cuoi != ._none) {
        print("!!! VIOLATE: 'ưa' sau không có âm cuối. VD: ưa\n", .{});
        return false;
    }

    if (am_giua == .uoz) switch (am_cuoi) {
        .ch, .nh, .u, .o, .y => {
            print("!!! VIOLATE: 'uô' không đi cùng `ch, nh, u, o, y`\n", .{});
            return false;
        },
        ._none => {
            print("!!! VIOLATE: 'uô' sau có âm cuối. VD: muốn\n", .{});
            return false;
        },
        else => {
            return true;
        },
    };

    if (am_giua == .ua and am_cuoi != ._none) {
        print("!!! VIOLATE: 'ua' sau không có âm cuối. VD: mua\n", .{});
        return false;
    }

    // Validate by am_cuoi last
    if (am_cuoi == .nh) switch (am_giua) {
        .e, .iez, .uoz, .uow => {
            print("!!! VIOLATE: 'e, iê, uô, ươ' không đi với `nh`\n", .{});
            return false;
        },
        else => return true,
    };

    if (am_cuoi == .ng) switch (am_giua) {
        .i, .ez => {
            if (am_dau == .gi) return true; // skip giêng
            print("!!! VIOLATE: 'i, ê' không đi với `ng`\n", .{});
            return false;
        },
        else => return true,
    };

    if (am_cuoi == .ch) switch (am_giua) {
        .e, .iez => {
            print("!!! VIOLATE: 'e, iê' không đi với `ch`\n", .{});
            return false;
        },
        else => return true,
    };

    if (am_cuoi == .c) switch (am_giua) {
        .i, .ez => {
            if (am_dau == .gi) return true; // skip giêc
            print("!!! VIOLATE: 'i, ê' không đi với `c`\n", .{});
            return false;
        },
        else => return true,
    };

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
                'w' => .uaw,
                else => .ua,
            },
            // 'e' => if (c2 == 'e') AmGiua.uez else .ue, // ue|uee quen,quên
            'e' => AmGiua.uez, // ue{e} => uez
            'w' => switch (c2) {
                'a' => AmGiua.uaw,
                'o' => .uow, // uwo{w} => uow, handle uwow len in parser
                else => .uw,
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
        'y' => if (c1 == 'e') AmGiua.iez else .y, // y|ye{e}
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
            'g' => if (c2 == 'h') AmDau.ngh else .ng,
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
    try expect(canBeVietnamese("hoon") == false);
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
    try expect(canBeVietnamese("tyeeu") == true); // convert to "tiêu"
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
    try expect(canBeVietnamese("iê") == false);
    try expect(canBeVietnamese("yê") == false);
    try expect(canBeVietnamese("niê") == false);
    try expect(canBeVietnamese("tyê") == false);
}

test "canBeVietnamese() // am_dau gi ko di cung am dem u, o" {
    try expect(canBeVietnamese("gioaj") == false);
    try expect(canBeVietnamese("gioas") == false);
    try expect(canBeVietnamese("giueej") == false);
    try expect(canBeVietnamese("giuyeen") == false);
    try expect(canBeVietnamese("giuyeetj") == false);
    try expect(canBeVietnamese("giuy") == false);
}

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

fn utf8ToTelex(str: []const u8) []const u8 {
    // return syllableToAmTiet(parseAmTietToGetSyllable(true, printNothing, str));
    var buffer: [11]u8 = undefined;
    const buff = buffer[0..];
    return parseAmTietToGetSyllable(true, printNothing, str).printBuffTelex(buff);
}

fn utf8ToUtf8(str: []const u8) []const u8 {
    // return syllableToAmTiet(parseAmTietToGetSyllable(true, printNothing, str));
    var buffer: [11]u8 = undefined;
    const buff = buffer[0..];
    return parseAmTietToGetSyllable(true, printNothing, str).printBuffUtf8(buff);
}

test "iee, yee (uyee), ooo, uee, uaz <= oaz" {
    try std.testing.expectEqualStrings(utf8ToTelex("ịa"), "iaj");
    try std.testing.expectEqualStrings(utf8ToTelex("tía"), "tias");
    try std.testing.expectEqualStrings(utf8ToUtf8("mịa"), "mịa");
    try std.testing.expectEqualStrings(utf8ToUtf8("yêu"), "yêu");
    try std.testing.expectEqualStrings(utf8ToUtf8("thuở"), "thủa");
    // Note: Need to convert no-mark format back to marked version for
    // following vowels:
    // .iee <= .ie,
    // .yee <= .ye,
    // .uyee <= .uye,
    // .uee <= .ue,
    // .uaz <= oaz
    // the user is aiming for 'ô' or 'oo' (both need to type double 'o')
    try std.testing.expectEqualStrings(utf8ToTelex("tuơ"), "tua");
    try std.testing.expectEqualStrings(utf8ToTelex("ngoẩy"), "nguaayr");
    try std.testing.expectEqualStrings(utf8ToTelex("toong"), "tooong");
    try std.testing.expectEqualStrings(utf8ToTelex("thoọng"), "thooongj");
    try std.testing.expectEqualStrings(utf8ToTelex("đoong"), "ddooong");

    try std.testing.expectEqualStrings(utf8ToTelex("voọc"), "vooocj");
    try std.testing.expectEqualStrings(strToAmTiet("tieu"), "tieeu");
    try std.testing.expectEqualStrings(strToAmTiet("yeu"), "yeeu");
    try std.testing.expectEqualStrings(strToAmTiet("tuyenr"), "tuyeenr");
    try std.testing.expectEqualStrings(strToAmTiet("tuej"), "tueej");
}

test "..." {
    try std.testing.expectEqualStrings(utf8ToTelex("BÔI"), "booi");
    try std.testing.expectEqualStrings(utf8ToTelex("BIÊN"), "bieen");
    try std.testing.expectEqualStrings(utf8ToTelex("CHUẨN"), "chuaanr");
    // try std.testing.expectEqualStrings(utf8ToTelex(""), "");
}

test "canBeVietnamese() // Auto-repair obvious cases" {
    try expect(canBeVietnamese("sưòn")); // sườn
    try expect(canBeVietnamese("suờn")); // sườn
    try expect(canBeVietnamese("tuơ")); // tua
    try expect(canBeVietnamese("tuơm")); // tươm
    try expect(canBeVietnamese("tiem")); // tiêm
    try expect(canBeVietnamese("tiém")); // tiếm
    try expect(canBeVietnamese("tuyen")); // tuyên
    try expect(canBeVietnamese("cưă")); // cưa
}

// - - -

test "canBeVietnamese() // alphamarks exceptions" {
    // try expect(canBeVietnameseStrict(""));

    try expect(canBeVietnameseStrict("gì"));
    try expect(canBeVietnameseStrict("A"));
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
    try expect(!canBeVietnameseStrict("khuắng"));
    try expect(canBeVietnameseStrict("khuều"));
    try expect(canBeVietnameseStrict("ngoẩy"));
    try expect(canBeVietnameseStrict("ðạo"));
    try expect(canBeVietnameseStrict("Ðạo"));
    try expect(canBeVietnameseStrict("nội"));
}

test "khả năng kết hợp âm cuối hiếm y, o, nh, ch" {
    try expect(canBeVietnameseStrict("ách"));
    try expect(canBeVietnameseStrict("ích"));
    try expect(canBeVietnameseStrict("ếch"));
    try expect(canBeVietnameseStrict("oách"));
    try expect(canBeVietnameseStrict("uỵch"));
    try expect(canBeVietnameseStrict("uệch"));
    //
    try expect(!canBeVietnameseStrict("uâch"));
    try expect(!canBeVietnameseStrict("ấch"));
    try expect(!canBeVietnameseStrict("ắch"));
    try expect(!canBeVietnameseStrict("ých"));
    try expect(!canBeVietnameseStrict("éch"));
    try expect(!canBeVietnameseStrict("ưch"));
    try expect(!canBeVietnameseStrict("óch"));
    try expect(!canBeVietnameseStrict("ốch"));
    try expect(!canBeVietnameseStrict("ớch"));
    try expect(!canBeVietnameseStrict("oẹch"));
    try expect(!canBeVietnameseStrict("oọch"));
    try expect(!canBeVietnameseStrict("oặch"));
    // std.debug.print("\n\n$$$ uộch $$$\n", .{});
    try expect(!canBeVietnameseStrict("uộch"));
    try expect(!canBeVietnameseStrict("uạch"));
    try expect(!canBeVietnameseStrict("ượch"));
    try expect(!canBeVietnameseStrict("ưạch"));
    try expect(!canBeVietnameseStrict("iệch"));
    try expect(!canBeVietnameseStrict("iạch"));
    try expect(!canBeVietnameseStrict("uyệch"));
    try expect(!canBeVietnameseStrict("uyạch"));

    try expect(canBeVietnameseStrict("anh"));
    try expect(canBeVietnameseStrict("inh"));
    try expect(canBeVietnameseStrict("ênh"));
    try expect(canBeVietnameseStrict("oanh"));
    try expect(canBeVietnameseStrict("uênh")); // huênh hoang
    try expect(canBeVietnameseStrict("uynh")); // huỳnh huỵch
    try expect(canBeVietnameseStrict("huỵch"));
    //
    try expect(!canBeVietnameseStrict("ânh"));
    try expect(!canBeVietnameseStrict("uânh"));
    try expect(!canBeVietnameseStrict("ănh"));
    try expect(!canBeVietnameseStrict("ynh"));
    try expect(!canBeVietnameseStrict("enh"));
    try expect(!canBeVietnameseStrict("ưnh"));
    try expect(!canBeVietnameseStrict("onh"));
    try expect(!canBeVietnameseStrict("ônh"));
    try expect(!canBeVietnameseStrict("ơnh"));
    try expect(!canBeVietnameseStrict("oenh"));
    try expect(!canBeVietnameseStrict("oonh"));
    try expect(!canBeVietnameseStrict("oănh"));
    try expect(!canBeVietnameseStrict("uônh"));
    try expect(!canBeVietnameseStrict("uanh"));
    try expect(!canBeVietnameseStrict("uơnh"));
    try expect(!canBeVietnameseStrict("ưanh"));
    try expect(!canBeVietnameseStrict("iênh"));
    try expect(!canBeVietnameseStrict("ianh"));
    try expect(!canBeVietnameseStrict("uyênh"));
    try expect(!canBeVietnameseStrict("uyanh"));

    // âm cuối y
    try expect(canBeVietnameseStrict("ay"));
    try expect(canBeVietnameseStrict("ây")); // tây
    try expect(canBeVietnameseStrict("oay")); // loay hoay
    try expect(canBeVietnameseStrict("uây")); // quây
    try expect(!canBeVietnameseStrict("ăy"));
    try expect(!canBeVietnameseStrict("iy"));
    try expect(!canBeVietnameseStrict("yy"));
    try expect(!canBeVietnameseStrict("ey"));
    try expect(!canBeVietnameseStrict("êy"));
    try expect(!canBeVietnameseStrict("ưy"));
    try expect(!canBeVietnameseStrict("oy"));
    try expect(!canBeVietnameseStrict("ôy"));
    try expect(!canBeVietnameseStrict("ơy"));
    try expect(!canBeVietnameseStrict("oey"));
    try expect(!canBeVietnameseStrict("ooy"));
    try expect(!canBeVietnameseStrict("oăy"));
    try expect(!canBeVietnameseStrict("uêy"));
    try expect(!canBeVietnameseStrict("uyy"));
    try expect(!canBeVietnameseStrict("uôy"));
    try expect(!canBeVietnameseStrict("uay"));
    try expect(!canBeVietnameseStrict("uơy"));
    try expect(!canBeVietnameseStrict("ưay"));
    try expect(!canBeVietnameseStrict("iêy"));
    try expect(!canBeVietnameseStrict("iay"));
    try expect(!canBeVietnameseStrict("uyêy"));
    try expect(!canBeVietnameseStrict("uyay"));

    try expect(canBeVietnameseStrict("ao"));
    try expect(canBeVietnameseStrict("eo"));
    try expect(canBeVietnameseStrict("oao")); // khoào
    try expect(canBeVietnameseStrict("oeo")); // toeo toét
    try expect(!canBeVietnameseStrict("âo"));
    try expect(!canBeVietnameseStrict("uâo"));
    try expect(!canBeVietnameseStrict("ăo"));
    try expect(!canBeVietnameseStrict("io"));
    try expect(!canBeVietnameseStrict("yo"));
    try expect(!canBeVietnameseStrict("êo"));
    // try expect(!canBeVietnameseStrict("ưo")); // auto convert to ươ
    try expect(!canBeVietnameseStrict("oo"));
    try expect(!canBeVietnameseStrict("ôo"));
    try expect(!canBeVietnameseStrict("ơo"));
    try expect(!canBeVietnameseStrict("ooo"));
    try expect(!canBeVietnameseStrict("oăo"));
    try expect(!canBeVietnameseStrict("uêo"));
    try expect(!canBeVietnameseStrict("uyo"));
    try expect(!canBeVietnameseStrict("uôo"));
    try expect(!canBeVietnameseStrict("uao"));
    try expect(!canBeVietnameseStrict("uơo"));
    try expect(!canBeVietnameseStrict("ưao"));
    try expect(!canBeVietnameseStrict("iêo"));
    try expect(!canBeVietnameseStrict("iao"));
    try expect(!canBeVietnameseStrict("uyêo"));
    try expect(!canBeVietnameseStrict("uyao"));
}

test "Support obvious rules nguyên âm đơn" {
    // a, â, ă
    try expect(canBeVietnameseStrict("am"));
    try expect(canBeVietnameseStrict("an"));
    try expect(canBeVietnameseStrict("áp"));
    try expect(canBeVietnameseStrict("ạt"));
    //
    try expect(canBeVietnameseStrict("ang"));
    try expect(canBeVietnameseStrict("anh"));
    try expect(canBeVietnameseStrict("ác"));
    try expect(canBeVietnameseStrict("ách"));
    try expect(canBeVietnameseStrict("ai"));
    try expect(canBeVietnameseStrict("ay"));
    try expect(canBeVietnameseStrict("ao"));
    try expect(canBeVietnameseStrict("au"));

    try expect(canBeVietnameseStrict("âm"));
    try expect(canBeVietnameseStrict("ân"));
    try expect(canBeVietnameseStrict("ập"));
    try expect(canBeVietnameseStrict("ất"));
    //
    try expect(canBeVietnameseStrict("âng")); // tâng bốc
    try expect(!canBeVietnameseStrict("ânh"));
    try expect(canBeVietnameseStrict("ấc")); // gấc
    try expect(!canBeVietnameseStrict("ậch"));
    try expect(!canBeVietnameseStrict("âi"));
    try expect(canBeVietnameseStrict("ây")); // tây
    try expect(!canBeVietnameseStrict("âo"));
    try expect(canBeVietnameseStrict("âu")); // tầu

    try expect(canBeVietnameseStrict("ăm"));
    try expect(canBeVietnameseStrict("ăn"));
    try expect(canBeVietnameseStrict("ắp"));
    try expect(canBeVietnameseStrict("ặt"));
    //
    try expect(canBeVietnameseStrict("ăng")); // tăng tốc
    try expect(!canBeVietnameseStrict("ănh"));
    try expect(canBeVietnameseStrict("ắc")); // tắc đường
    try expect(!canBeVietnameseStrict("ắch"));
    try expect(!canBeVietnameseStrict("ăi"));
    try expect(!canBeVietnameseStrict("ăy"));
    try expect(!canBeVietnameseStrict("ăo"));
    try expect(!canBeVietnameseStrict("ău"));

    // i, y
    try expect(canBeVietnameseStrict("im"));
    try expect(canBeVietnameseStrict("in"));
    try expect(canBeVietnameseStrict("íp"));
    try expect(canBeVietnameseStrict("ịt"));
    //
    try expect(!canBeVietnameseStrict("ing"));
    try expect(canBeVietnameseStrict("inh"));
    try expect(!canBeVietnameseStrict("íc"));
    try expect(canBeVietnameseStrict("ịch"));
    try expect(!canBeVietnameseStrict("ii"));
    try expect(!canBeVietnameseStrict("iy"));
    try expect(!canBeVietnameseStrict("io"));
    try expect(canBeVietnameseStrict("iu"));

    try expect(!canBeVietnameseStrict("ym"));
    try expect(!canBeVietnameseStrict("yn"));
    try expect(!canBeVietnameseStrict("ýp"));
    try expect(!canBeVietnameseStrict("ỵt"));
    //
    try expect(!canBeVietnameseStrict("yng"));
    try expect(!canBeVietnameseStrict("ynh"));
    try expect(!canBeVietnameseStrict("ýc"));
    try expect(!canBeVietnameseStrict("ỵch"));
    try expect(!canBeVietnameseStrict("yi"));
    try expect(!canBeVietnameseStrict("yy"));
    try expect(!canBeVietnameseStrict("yo"));
    try expect(!canBeVietnameseStrict("yu"));

    // e, ê
    try expect(canBeVietnameseStrict("em"));
    try expect(canBeVietnameseStrict("en"));
    try expect(canBeVietnameseStrict("ép"));
    try expect(canBeVietnameseStrict("ẹt"));
    //
    try expect(canBeVietnameseStrict("eng"));
    try expect(!canBeVietnameseStrict("enh"));
    try expect(canBeVietnameseStrict("éc"));
    try expect(!canBeVietnameseStrict("ẹch"));
    try expect(!canBeVietnameseStrict("ei"));
    try expect(!canBeVietnameseStrict("ey"));
    try expect(canBeVietnameseStrict("eo"));
    try expect(!canBeVietnameseStrict("eu"));

    try expect(canBeVietnameseStrict("êm"));
    try expect(canBeVietnameseStrict("ên"));
    try expect(canBeVietnameseStrict("ệp"));
    try expect(canBeVietnameseStrict("ết"));
    //
    try expect(!canBeVietnameseStrict("êng"));
    try expect(canBeVietnameseStrict("ênh"));
    try expect(canBeVietnameseStrict("ếch"));
    try expect(!canBeVietnameseStrict("ệc"));
    try expect(!canBeVietnameseStrict("êi"));
    try expect(!canBeVietnameseStrict("êy"));
    try expect(!canBeVietnameseStrict("êo"));
    try expect(canBeVietnameseStrict("êu"));

    // u, ư
    try expect(canBeVietnameseStrict("um"));
    try expect(canBeVietnameseStrict("un"));
    try expect(canBeVietnameseStrict("úp"));
    try expect(canBeVietnameseStrict("ụt"));
    //
    try expect(canBeVietnameseStrict("ung")); // tùng
    try expect(!canBeVietnameseStrict("unh"));
    try expect(canBeVietnameseStrict("úc")); // túc trực
    try expect(!canBeVietnameseStrict("ụch"));
    try expect(canBeVietnameseStrict("ui")); // túi
    // try expect(canBeVietnameseStrict("uy")); // nguyên âm đôi uy
    try expect(!canBeVietnameseStrict("uo"));
    try expect(!canBeVietnameseStrict("uu"));

    try expect(canBeVietnameseStrict("ưm"));
    try expect(canBeVietnameseStrict("ưn"));
    try expect(canBeVietnameseStrict("ựp"));
    try expect(canBeVietnameseStrict("ựt"));
    //
    try expect(canBeVietnameseStrict("ưng")); // từng
    try expect(!canBeVietnameseStrict("ưnh"));
    try expect(canBeVietnameseStrict("ực")); // bực tức
    try expect(!canBeVietnameseStrict("ứch"));
    try expect(canBeVietnameseStrict("ưi")); // gửi
    try expect(!canBeVietnameseStrict("ưy"));
    // try expect(canBeVietnameseStrict("ưo")); // nguyên âm đôi ươ
    try expect(canBeVietnameseStrict("ưu")); // ưu tú

    // o, ô, ơ
    try expect(canBeVietnameseStrict("om"));
    try expect(canBeVietnameseStrict("on"));
    try expect(canBeVietnameseStrict("óp"));
    try expect(canBeVietnameseStrict("ọt"));
    //
    try expect(canBeVietnameseStrict("ong")); // tòng
    try expect(!canBeVietnameseStrict("onh"));
    try expect(canBeVietnameseStrict("óc")); // tóc
    try expect(!canBeVietnameseStrict("ọch"));
    try expect(canBeVietnameseStrict("oi")); // toi
    try expect(!canBeVietnameseStrict("oy"));
    // try expect(canBeVietnameseStrict("oo")); // nguyên âm 'oo' trong boong
    try expect(!canBeVietnameseStrict("ou"));

    try expect(canBeVietnameseStrict("ôm"));
    try expect(canBeVietnameseStrict("ôn"));
    try expect(canBeVietnameseStrict("ốp"));
    try expect(canBeVietnameseStrict("ốt"));
    //
    try expect(canBeVietnameseStrict("ông")); // tông
    try expect(!canBeVietnameseStrict("ônh"));
    try expect(canBeVietnameseStrict("ộc")); // tộc
    try expect(!canBeVietnameseStrict("ốch"));
    try expect(canBeVietnameseStrict("ôi")); // tôi
    try expect(!canBeVietnameseStrict("ôy"));
    try expect(!canBeVietnameseStrict("ôo"));
    try expect(!canBeVietnameseStrict("ôu"));

    try expect(canBeVietnameseStrict("ơm"));
    try expect(canBeVietnameseStrict("ơn"));
    try expect(canBeVietnameseStrict("ớp"));
    try expect(canBeVietnameseStrict("ợt"));
    //
    try expect(canBeVietnameseStrict("ơng")); // tơng
    try expect(!canBeVietnameseStrict("ơnh"));
    try expect(canBeVietnameseStrict("ớc")); // tớc
    try expect(!canBeVietnameseStrict("ợch"));
    try expect(canBeVietnameseStrict("ơi")); // tơi
    try expect(!canBeVietnameseStrict("ơy"));
    try expect(!canBeVietnameseStrict("ơo"));
    // try expect(canBeVietnameseStrict("ơu")); // âm đôi ươ
}

test "Support obvious rules nguyên âm đôi / ba" {
    try expect(canBeVietnameseStrict("oam"));
    try expect(canBeVietnameseStrict("oan"));
    try expect(canBeVietnameseStrict("oáp"));
    try expect(canBeVietnameseStrict("oạt"));
    //
    try expect(canBeVietnameseStrict("oang")); // sáng choang
    try expect(canBeVietnameseStrict("oanh")); // oanh
    try expect(canBeVietnameseStrict("oác")); // toác
    try expect(canBeVietnameseStrict("oách")); // toách
    try expect(canBeVietnameseStrict("oai"));
    try expect(canBeVietnameseStrict("oay")); // loay hoay
    try expect(canBeVietnameseStrict("oao")); // khoào
    try expect(!canBeVietnameseStrict("oau"));

    try expect(canBeVietnameseStrict("oem"));
    try expect(canBeVietnameseStrict("oen"));
    try expect(canBeVietnameseStrict("oép"));
    try expect(canBeVietnameseStrict("oẹt"));
    //
    try expect(canBeVietnameseStrict("oeng")); // xoèng xoèng, linh tinh xoèng
    try expect(!canBeVietnameseStrict("oenh"));
    try expect(canBeVietnameseStrict("oéc"));
    try expect(!canBeVietnameseStrict("oéch"));
    try expect(!canBeVietnameseStrict("oei"));
    try expect(!canBeVietnameseStrict("oey"));
    try expect(canBeVietnameseStrict("oeo")); // toeo toé
    try expect(!canBeVietnameseStrict("oeu"));

    try expect(!canBeVietnameseStrict("oom"));
    try expect(!canBeVietnameseStrict("oon"));
    try expect(!canBeVietnameseStrict("oóp"));
    try expect(!canBeVietnameseStrict("oọt"));
    //
    try expect(canBeVietnameseStrict("oong")); // boong
    try expect(!canBeVietnameseStrict("oonh"));
    try expect(canBeVietnameseStrict("oóc")); // coóc
    try expect(!canBeVietnameseStrict("oóch"));
    try expect(!canBeVietnameseStrict("ooi"));
    try expect(!canBeVietnameseStrict("ooy"));
    try expect(!canBeVietnameseStrict("ooo"));
    try expect(!canBeVietnameseStrict("oou"));

    // oă
    try expect(canBeVietnameseStrict("oăm"));
    try expect(canBeVietnameseStrict("oăn"));
    try expect(canBeVietnameseStrict("oắp"));
    try expect(canBeVietnameseStrict("oặt"));
    //
    try expect(canBeVietnameseStrict("oăng")); // hoăng hoắc
    try expect(!canBeVietnameseStrict("oănh"));
    try expect(canBeVietnameseStrict("oặc"));
    try expect(!canBeVietnameseStrict("oắch"));
    try expect(!canBeVietnameseStrict("oăi"));
    try expect(!canBeVietnameseStrict("oăy"));
    try expect(!canBeVietnameseStrict("oăo"));
    try expect(!canBeVietnameseStrict("oău"));

    // uâ
    try expect(canBeVietnameseStrict("uâm"));
    try expect(canBeVietnameseStrict("uân"));
    try expect(canBeVietnameseStrict("uấp"));
    try expect(canBeVietnameseStrict("uật"));
    //
    try expect(canBeVietnameseStrict("uâng"));
    try expect(!canBeVietnameseStrict("uânh"));
    try expect(canBeVietnameseStrict("uấc"));
    try expect(!canBeVietnameseStrict("uấch"));
    try expect(!canBeVietnameseStrict("uâi"));
    try expect(canBeVietnameseStrict("uây")); // quây
    try expect(!canBeVietnameseStrict("uâo"));
    try expect(!canBeVietnameseStrict("uâu"));

    // uê
    try expect(canBeVietnameseStrict("uêm"));
    try expect(canBeVietnameseStrict("uên"));
    try expect(canBeVietnameseStrict("uếp"));
    try expect(canBeVietnameseStrict("uệt"));
    //
    try expect(!canBeVietnameseStrict("uêng"));
    try expect(canBeVietnameseStrict("uênh")); // huênh hoang
    try expect(!canBeVietnameseStrict("uếc"));
    try expect(canBeVietnameseStrict("uếch"));
    try expect(!canBeVietnameseStrict("uêi"));
    try expect(!canBeVietnameseStrict("uêy"));
    try expect(!canBeVietnameseStrict("uêo"));
    try expect(!canBeVietnameseStrict("uêu"));

    try expect(!canBeVietnameseStrict("uym"));
    try expect(canBeVietnameseStrict("uyn")); // màn tuyn
    try expect(canBeVietnameseStrict("uýp")); // tuýp người
    try expect(canBeVietnameseStrict("uỵt")); // tuýt còi
    //
    try expect(!canBeVietnameseStrict("uyng"));
    try expect(canBeVietnameseStrict("uynh")); // huỳnh
    try expect(!canBeVietnameseStrict("uýc"));
    try expect(canBeVietnameseStrict("uỵch")); // huỵch, huých
    try expect(!canBeVietnameseStrict("uyi"));
    try expect(!canBeVietnameseStrict("uyy"));
    try expect(!canBeVietnameseStrict("uyo"));
    try expect(canBeVietnameseStrict("uyu")); // khuỵu

    // uô, ua
    try expect(canBeVietnameseStrict("uôm"));
    try expect(canBeVietnameseStrict("uôn"));
    try expect(canBeVietnameseStrict("uốp"));
    try expect(canBeVietnameseStrict("uột"));
    //
    try expect(canBeVietnameseStrict("uông"));
    try expect(canBeVietnameseStrict("uốc"));
    try expect(canBeVietnameseStrict("uộp"));
    // try expect(!canBeVietnameseStrict("uộch"));
    try expect(!canBeVietnameseStrict("uônh"));
    try expect(canBeVietnameseStrict("uôi"));
    try expect(!canBeVietnameseStrict("uôy"));
    try expect(!canBeVietnameseStrict("uôu"));
    try expect(!canBeVietnameseStrict("uôo"));
    try expect(!canBeVietnameseStrict("uoo"));

    try expect(canBeVietnameseStrict("ua"));
    try expect(!canBeVietnameseStrict("uam"));
    try expect(!canBeVietnameseStrict("uan"));
    try expect(!canBeVietnameseStrict("uáp"));
    try expect(!canBeVietnameseStrict("uạt"));
    //
    try expect(!canBeVietnameseStrict("uang"));
    try expect(!canBeVietnameseStrict("uac"));
    try expect(!canBeVietnameseStrict("uap"));
    try expect(!canBeVietnameseStrict("uach"));
    try expect(!canBeVietnameseStrict("uanh"));
    try expect(!canBeVietnameseStrict("uai"));
    try expect(!canBeVietnameseStrict("uay"));
    try expect(!canBeVietnameseStrict("uau"));
    try expect(!canBeVietnameseStrict("uao"));

    // ươ, ưa
    try expect(canBeVietnameseStrict("ưỡm"));
    try expect(canBeVietnameseStrict("ưõn"));
    try expect(canBeVietnameseStrict("ượp"));
    try expect(canBeVietnameseStrict("ượt"));
    //
    try expect(canBeVietnameseStrict("ương"));
    try expect(!canBeVietnameseStrict("uơnh"));
    try expect(canBeVietnameseStrict("ước"));
    try expect(!canBeVietnameseStrict("uớch"));
    try expect(canBeVietnameseStrict("ươi"));
    try expect(!canBeVietnameseStrict("uơy"));
    try expect(canBeVietnameseStrict("uơu"));
    try expect(!canBeVietnameseStrict("uơo"));
    try expect(canBeVietnameseStrict("ươu"));
    try expect(!canBeVietnameseStrict("ươo"));

    try expect(canBeVietnameseStrict("ưa"));
    try expect(!canBeVietnameseStrict("ưam"));
    try expect(!canBeVietnameseStrict("ưan"));
    try expect(!canBeVietnameseStrict("ứap"));
    try expect(!canBeVietnameseStrict("ứat"));
    //
    try expect(!canBeVietnameseStrict("ưang"));
    try expect(!canBeVietnameseStrict("ưanh"));
    try expect(!canBeVietnameseStrict("ưác"));
    try expect(!canBeVietnameseStrict("ứach"));
    try expect(!canBeVietnameseStrict("ưai"));
    try expect(!canBeVietnameseStrict("ưay"));
    try expect(!canBeVietnameseStrict("ưau"));
    try expect(!canBeVietnameseStrict("ưao"));
    try expect(!canBeVietnameseStrict("ưau"));
    try expect(!canBeVietnameseStrict("ưao"));

    // iê, ia, uyê, uya (tổ  hợp âm đệm `u` với nguyên âm đôi `iê`)
    try expect(canBeVietnameseStrict("iêm"));
    try expect(canBeVietnameseStrict("iên"));
    try expect(canBeVietnameseStrict("iệp"));
    try expect(canBeVietnameseStrict("iết"));
    //
    try expect(canBeVietnameseStrict("iêng"));
    try expect(!canBeVietnameseStrict("iênh"));
    try expect(!canBeVietnameseStrict("iếch"));
    try expect(canBeVietnameseStrict("iếc"));
    try expect(!canBeVietnameseStrict("iêi"));
    try expect(!canBeVietnameseStrict("iêy"));
    try expect(!canBeVietnameseStrict("iêo"));
    try expect(canBeVietnameseStrict("iêu"));

    try expect(canBeVietnameseStrict("ia"));
    try expect(!canBeVietnameseStrict("iam"));
    try expect(!canBeVietnameseStrict("ian"));
    try expect(!canBeVietnameseStrict("íap"));
    try expect(!canBeVietnameseStrict("iát"));
    //
    try expect(!canBeVietnameseStrict("iang"));
    try expect(!canBeVietnameseStrict("ianh"));
    try expect(!canBeVietnameseStrict("iach"));
    try expect(!canBeVietnameseStrict("iac"));
    try expect(!canBeVietnameseStrict("iai"));
    try expect(!canBeVietnameseStrict("iay"));
    try expect(!canBeVietnameseStrict("iao"));
    try expect(!canBeVietnameseStrict("iau"));

    try expect(!canBeVietnameseStrict("uyêm"));
    try expect(canBeVietnameseStrict("uyên"));
    try expect(!canBeVietnameseStrict("uyệp"));
    try expect(canBeVietnameseStrict("uyết"));
    //
    try expect(!canBeVietnameseStrict("uyêng"));
    try expect(!canBeVietnameseStrict("uyênh"));
    try expect(!canBeVietnameseStrict("uyếch"));
    try expect(!canBeVietnameseStrict("uyếc"));
    try expect(!canBeVietnameseStrict("uyêi"));
    try expect(!canBeVietnameseStrict("uyêy"));
    try expect(!canBeVietnameseStrict("uyêo"));
    try expect(!canBeVietnameseStrict("uyêu"));

    try expect(canBeVietnameseStrict("uya"));
    try expect(!canBeVietnameseStrict("uyam"));
    try expect(!canBeVietnameseStrict("uyan"));
    try expect(!canBeVietnameseStrict("uyap"));
    try expect(!canBeVietnameseStrict("uyat"));
    //
    try expect(!canBeVietnameseStrict("uyang"));
    try expect(!canBeVietnameseStrict("uyanh"));
    try expect(!canBeVietnameseStrict("uyách"));
    try expect(!canBeVietnameseStrict("uyác"));
    try expect(!canBeVietnameseStrict("uyai"));
    try expect(!canBeVietnameseStrict("uyay"));
    try expect(!canBeVietnameseStrict("uyao"));
    try expect(!canBeVietnameseStrict("uyau"));
}

test "Support obvious rules âm đầu không đi với nguyên âm" {
    try expect(!canBeVietnameseStrict("coa"));
    try expect(canBeVietnameseStrict("quan"));

    try expect(!canBeVietnameseStrict("coen"));
    try expect(canBeVietnameseStrict("quen"));

    try expect(!canBeVietnameseStrict("chuan"));

    try expect(!canBeVietnameseStrict("coăn"));
    try expect(canBeVietnameseStrict("quăn"));
}

test "Syllable.normalize" {
    var buffer: [13]u8 = undefined;
    const buff = buffer[0..];
    var syll = parseAmTietToGetSyllable(true, printNothing, "nghuyen");
    try std.testing.expectEqualStrings(syll.printBuffUtf8(buff), "nguyên");
}

fn canBeVietnameseDebug(am_tiet: []const u8) bool {
    return parseAmTietToGetSyllable(true, std.debug.print, am_tiet).can_be_vietnamese;
}

fn canBeVietnameseStrict(am_tiet: []const u8) bool {
    // return parseAmTietToGetSyllable(true, std.debug.print, am_tiet).can_be_vietnamese;
    return parseAmTietToGetSyllable(true, printNothing, am_tiet).can_be_vietnamese;
}

test "Spelling errors @ 08-syllower_freqs.txt and 09-syllovan_freqs.txt" {
    // quyeu, quuyen, quyng, cuyen, huyu, quung, queng
    // try expect(!canBeVietnameseStrict("chuẩm")); // => chuẩn or chẩm
    // try expect(!canBeVietnameseStrict("quyểng")); // => quyển
    // try expect(!canBeVietnameseStrict("quyểm")); // => quyển
    // try expect(!canBeVietnameseStrict("quyếc")); // quyếch
    // try expect(!canBeVietnameseStrict("loao")); // OK: khoào
    // 9 uua|
    // 8 oep|
    // 7 iuoi|
    // 7 uoe|
    // 6 yec|
    // 6 uoan|
    // 6 uoay|
    // 5 uoang|
    // 4 uec|
    // 4 uich|
    // 4 uia|
    // 3 oec|
    // 3 uuyen|
    // 3 ueu|
    // 3 uuynh|
    // 2 uyng|
    // 2 uuan|
    // 2 uut|
    // 2 uyem|
    // 2 uuen|
    // 2 iuon|
    // 2 yep|
    // 2 uoen|
    // 1 uyeng|
    // 1 iuom|
    // 1 iach|
    // 1 uep|
    // 1 uung|
    // 1 uoat|
    // 1 uyeu|
    // 1 uuyet|
    // 1 uyec|
    // 1 uym|
    // 1 uoach|
    // 1 uoet|
    // 1 uoac|
}
