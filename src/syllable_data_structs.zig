const std = @import("std");
const expect = std.testing.expect;
const fmt = std.fmt;

// Ref https://tieuluan.info/ti-liu-bdhsg-mn-ting-vit-lp-4-5.html?page=11

/// Tiếng gồm 3 bộ phận : phụ âm đầu, vần và thanh điệu.
/// - Tiếng nào cũng có vần và thanh. Có tiếng không có phụ âm đầu.
/// - Tiếng Việt có 6 thanh: thanh ngang (còn gọi là thanh không), thanh huyền, thanh sắc, thanh hỏi, thanh ngã, thanh nặng.

// Các phụ âm đầu, vần (nguyên âm và phụ âm cuối) được tạo thành từ:
/// - 22 phụ âm : b, c (k,q), ch, d, đ, g (gh), h, kh, l, m, n, nh, ng (ngh), p, ph, r, s, t, tr, th, v, x.
/// - 11 nguyên âm: i, e, ê, ư, u, o, ô, ơ, a, ă, â.
pub const AmDau = enum(u5) {
    _none,
    b,
    c,
    d,
    g,
    h,
    k,
    l,
    m,
    n,
    p,
    r,
    s,
    t,
    v,
    x,
    ch,
    zd,
    gh,
    gi, // dùng như âm d
    kh,
    ng,
    nh,
    ph,
    qu, // q + âm đệm u, chuyển lên đây để giảm tải cho AmGiua
    th,
    tr,
    ngh,
    pub fn len(self: AmDau) u8 {
        return switch (@enumToInt(self)) {
            1...15 => 1,
            16...26 => 2,
            27 => 3,
            else => 0,
        };
    }
    pub fn isSaturated(self: AmDau) bool {
        if (self.len() == 3) return true;
        if (self.len() == 2 and self != .ng) return true;
        if (self.len() == 1) {
            switch (self) {
                .c, .d, .g, .k, .n, .p, .t => {
                    return false;
                },
                else => {
                    return true;
                },
            }
        }
        return false;
    }
    pub fn noMark(self: AmDau) AmDau {
        return switch (self) {
            .zd => .d,
            else => self,
        };
    }
};

test "Enum AmDau" {
    try expect(AmDau.b.len() == 1);
    try expect(AmDau.x.len() == 1);
    try expect(AmDau.ch.len() == 2);
    try expect(AmDau.tr.len() == 2);
    try expect(AmDau.ngh.len() == 3);
    try expect(AmDau._none.len() == 0);
    try expect(AmDau._none.isSaturated() == false);
    try expect(AmDau.zd.isSaturated() == true);
}

/// https://tieuluan.info/ti-liu-bdhsg-mn-ting-vit-lp-4-5.html?page=12
/// 2.Vần gồm có 3 phần : âm đệm, âm chính, âm cuối.
/// - Âm đệm được ghi bằng con chữ u và o.
///     + Ghi bằng con chữ o khi đứng trước các nguyên âm: a, ă, e.
///     + Ghi bằng con chữ u khi đứng trước các nguyên âm y, ê, ơ, â.
/// - Âm đệm không xuất hiện sau các phụ âm b, m, v, ph, n, r, g. Trừ các trường hợp:
///     + sau ph, b: thùng phuy, voan, ô tô buýt (là từ nước ngoài)
///     + sau n: thê noa, noãn sào (2 từ Hán Việt)
///     + sau r: roàn roạt.(1 từ)
///     + sau g: goá (1 từ)
/// Trong Tiếng Việt, nguyên âm nào cũng có thể làm âm chính của tiếng.
/// - Các nguyên âm đơn: (11 nguyên âm ghi ở trên)
/// - Các nguyên âm đôi: Có 3 nguyên âm đôi và được tách thành 8 nguyên âm sau:
// * iê:
// Ghi bằng ia khi phía trước không có âm đệm và phía sau không có âm cuối (VD: mía, tia, kia,...)
// Ghi bằng yê khi phía trước có âm đệm hoặc không có âm nào, phía sau có âm cuối (VD: yêu, chuyên,...)
// Ghi bằng ya khi phía trước có âm đệm và phía sau không có âm cuối (VD: khuya,...)
// Ghi bằng iê khi phía trước có phụ âm đầu, phía sau có âm cuối (VD: tiên, kiến,...)
//
// + uơ:
// Ghi bằng ươ khi sau nó có âm cuối ( VD: mượn,...)
// Ghi bằng ưa khi phía sau nó không có âm cuối (VD: mưa,...)
//
// + uô:
// Ghi bằng uô khi sau nó có âm cuối (VD: muốn,...)
// Ghi bằng ua khi sau nó không có âm cuối (VD: mua,...)

pub const AmGiua = enum(u5) {
    _none,
    a,
    e,
    i,
    o,
    u,
    y,

    az, // â
    aw, // ă
    ez, // ê
    oz, // ô
    ow, // ơ
    uw, // ư

    ua,
    ia,
    oa,
    oe,
    ooo, // boong
    uo, // <= 'uoz', 'uow' without mark
    uy,
    iez, // iê
    oaw, // oă
    uaz, // uâ
    uez, // uê
    uoz, // uô
    uaw, // ưa
    uya,
    yez, // yê
    uow, // ươ
    uyez, // uyê

    // uow, // “thuở/thủa” => convert to "ủa" nếu muốn chuẩn hoá
    // http://repository.ulis.vnu.edu.vn/handle/ULIS_123456789/164
    // Về việc hiển thị và bộ gõ thì ko cần convert vì thuở sẽ ko đi cùng âm cuối, và ngược lại ươ ko đứng riêng mà cần âm cuối đi kèm.

    pub fn startWithIY(self: AmGiua) bool {
        return switch (self) {
            .i, .y, .ia, .iez, .yez => true,
            else => false,
        };
    }
    pub fn hasMark(self: AmGiua) bool {
        return switch (self) {
            .az, .aw, .ez, .uw, .oz, .ow, .oaw, .uaz, .uez, .uow, .uoz, .uaw, .iez, .yez, .uyez => true,
            else => false,
        };
    }
    pub fn len(self: AmGiua) u8 {
        return switch (@enumToInt(self)) {
            1...6 => 1,
            7...19 => 2,
            20...27 => 3,
            28, 29 => 4,
            else => 0,
        };
    }
    pub fn isSaturated(self: AmGiua) bool {
        if (self.len() == 4 or self.len() == 3) return true;
        if (self.len() == 2) {
            switch (self) {
                .oa, .ooo, .ua, .uo, .uw, .uy => {
                    return false;
                },
                else => {
                    return true;
                },
            }
        }
        return false;
    }
    pub fn hasAmDem(self: AmGiua) bool {
        return switch (self) {
            .uaa, .uee, .uy, .uyee, .uya => true,
            .oa, .oaw, .oe, .ooo => true,
            else => false,
        };
    }
    pub fn noMark(self: AmGiua) AmGiua {
        return switch (self) {
            .az => .a,
            .aw => .a,
            .ez => .e,
            .oz => .o,
            .ow => .o,
            .uw => .u,
            .oaw => .oa,
            .uaz => .ua,
            .uaw => .ua,
            .uoz => .uo,
            .uow => .uo,
            .iez => .ie,
            .yez => .ye,
            .uyez => .uye,
            else => self,
        };
    }
};

test "Enum AmGiua" {
    try expect(AmGiua.a.len() == 1);
    try expect(AmGiua.y.len() == 1);
    try expect(AmGiua.az.len() == 2);
    try expect(AmGiua.uy.len() == 2);
    try expect(AmGiua.iez.len() == 3);
    try expect(AmGiua.yez.len() == 3);
    try expect(AmGiua.uow.len() == 4);
    try expect(AmGiua.uyez.len() == 4);
    try expect(AmGiua._none.len() == 0);
}

/// * Âm cuối:
/// - Các phụ âm cuối vần : p, t, c (ch), m, n, ng (nh)
/// - 2 bán âm cuối vần : i (y), u (o)
pub const AmCuoi = enum(u4) {
    _none,
    c,
    m,
    n,
    p,
    t,
    i,
    y,
    u,
    o,
    ch,
    ng,
    nh,
    pub fn len(self: AmCuoi) u8 {
        return switch (@enumToInt(self)) {
            1...9 => 1,
            10, 11, 12 => 2,
            else => 0,
        };
    }
    pub fn isSaturated(self: AmCuoi) bool {
        if (self.len() == 2) return true;
        if (self.len() == 1) {
            switch (self) {
                .c, .n => {
                    return false;
                },
                else => {
                    return true;
                },
            }
        }
        return false;
    }
    pub fn isStop(self: AmCuoi) bool {
        return switch (self) {
            .c, .t, .p, .ch => true,
            else => false,
        };
    }
};

test "Enum AmCuoi.len" {
    try expect(AmCuoi.c.len() == 1);
    try expect(AmCuoi.y.len() == 1);
    try expect(AmCuoi.ch.len() == 2);
    try expect(AmCuoi.nh.len() == 2);
    try expect(AmCuoi._none.len() == 0);
}

pub const Tone = enum(u3) {
    _none,
    s,
    f,
    r,
    x,
    j,
    pub fn len(self: Tone) u8 {
        return if (self == ._none) 0 else 1;
    }
    pub fn isSaturated(self: Tone) bool {
        return self != ._none;
    }
    pub fn isStop(self: Tone) bool {
        return switch (self) {
            .s, .j => true,
            else => false,
        };
    }
    pub fn canBeStop(self: Tone) bool {
        return switch (self) {
            // add ._none to support no-tone vi syllable
            .s, .j, ._none => true,
            else => false,
        };
    }
    pub fn isHarsh(self: Tone) bool {
        return switch (self) {
            .x, .j => true,
            else => false,
        };
    }
};

test "Enum Tone.isHarsh" {
    try expect(Tone.x.isHarsh() == true);
    try expect(Tone.j.isHarsh() == true);
    try expect(Tone.s.isHarsh() == false);
}

pub const Syllable = packed struct {
    can_be_vietnamese: bool, // 1 bit
    am_dau: AmDau, //           5 bits
    am_giua: AmGiua, //         5 bits
    am_cuoi: AmCuoi, //         4 bits
    tone: Tone, //              3 bits
    //                         - - - -
    //                   Total 18 bits
    // 2^17 = 131k not syllable tokens

    pub const UniqueId = u18; // @bitSizeOf(Syllable);

    pub fn toId(self: Syllable) UniqueId {
        return @bitCast(UniqueId, self);
    }

    pub fn newFromId(id: UniqueId) Syllable {
        return @bitCast(Syllable, id);
    }

    pub fn new() Syllable {
        return .{
            .am_dau = ._none,
            .am_giua = ._none,
            .am_cuoi = ._none,
            .tone = ._none,
            .can_be_vietnamese = false,
        };
    }
    pub fn reset(self: *Syllable) void {
        self.am_dau = ._none;
        self.am_giua = ._none;
        self.am_cuoi = ._none;
        self.tone = ._none;
        self.can_be_vietnamese = false;
    }

    pub fn printBuffParts(self: *Syllable, buff: []u8) []const u8 {
        const blank = "";
        const dau = switch (self.am_dau) {
            ._none => blank,
            .zd => "dd",
            .ngh => "ng",
            .gh => "g",
            else => @tagName(self.am_dau),
        };
        const giua = switch (self.am_giua) {
            .ooo => "oo",
            else => @tagName(self.am_giua),
        };
        const cuoi = if (self.am_cuoi == ._none) blank else @tagName(self.am_cuoi);

        var n: usize = 0;

        // dau
        if (dau.len > 0) {
            buff[n] = '_';
            n += 1;
            for (dau) |byte| {
                buff[n] = byte;
                n += 1;
            }
        }

        // giua
        if (giua.len > 0) {
            if (buff[n - 1] == 'u') { // qu => q u
                buff[n - 1] = 32;
                buff[n] = 'u';
                n += 1;
            } else {
                buff[n] = 32;
                n += 1;
            }
            for (giua) |byte| {
                buff[n] = byte;
                n += 1;
            }
        }

        // cuoi
        if (cuoi.len > 0) {
            buff[n] = 32;
            n += 1;
            for (cuoi) |byte| {
                buff[n] = byte;
                n += 1;
            }
        }

        // tone
        if (self.tone != ._none) {
            buff[n] = 32;
            n += 1;
            buff[n] = @tagName(self.tone)[0];
            n += 1;
        }
        return buff[0..n];
    }

    pub fn printBuffTelex(self: *Syllable, buff: []u8) []const u8 {
        const blank = "";
        const dau = switch (self.am_dau) {
            ._none => blank,
            .zd => "dd",
            else => @tagName(self.am_dau),
        };
        const giua = switch (self.am_giua) {
            ._none => blank,
            .uoz => "uoo",
            .uaz => "uaa",
            .uaw => "uwa",
            .uez => "uee",
            .az => "aa",
            .ez => "ee",
            .oz => "oo",
            .iez => "iee",
            .yez => "yee",
            .uyez => "uyee",
            .uow => "uwow",
            else => @tagName(self.am_giua),
        };
        const cuoi = if (self.am_cuoi == ._none) blank else @tagName(self.am_cuoi);
        const tone = if (self.tone == ._none) blank else @tagName(self.tone);

        std.debug.assert(buff.len >= dau.len + giua.len + cuoi.len + tone.len);

        var n: usize = 0;
        const parts: [4][]const u8 = .{ dau, giua, cuoi, tone };

        for (parts) |s| {
            for (s) |b| {
                buff[n] = b;
                n += 1;
            }
        }
        return buff[0..n];
    }

    pub fn printBuffUtf8(self: *Syllable, buff: []u8) []const u8 {
        const blank = "";
        const dau = switch (self.am_dau) {
            ._none => blank,
            .zd => "đ",
            else => @tagName(self.am_dau),
        };
        const giua = switch (self.tone) {
            ._none => switch (self.am_giua) {
                ._none => blank,
                .oaw => "oă",
                .aw => "ă",
                .uw => "ư",
                .ow => "ơ",
                .uoz => "uô",
                .uaz => "uâ",
                .uaw => "ưa",
                .uez => "uê",
                .az => "â",
                .ez => "ê",
                .oz => "ô",
                .iez => "iê",
                .yez => "yê",
                .uyez => "uyê",
                .uow => "ươ",
                .ooo => "oo",
                else => @tagName(self.am_giua),
            },
            .s => switch (self.am_giua) {
                ._none => blank,
                .oaw => "oắ",
                .aw => "ắ",
                .uw => "ứ",
                .ow => "ớ",
                .uoz => "uố",
                .uaz => "uấ",
                .uaw => "ứa",
                .uez => "uế",
                .az => "ấ",
                .ez => "ế",
                .oz => "ố",
                .iez => "iế",
                .yez => "yế",
                .uyez => "uyế",
                .uow => "ướ",
                .a => "á",
                .e => "é",
                .i => "í",
                .u => "ú",
                .y => "ý",
                .o => "ó",
                .ua => "úa",
                .ia => "ía",
                .oa => "oá",
                .oe => "oé",
                .ooo => "oó",
                .uy => "uý",
                else => @tagName(self.am_giua),
            },
            .f => switch (self.am_giua) {
                ._none => blank,
                .oaw => "oằ",
                .aw => "ằ",
                .uw => "ừ",
                .ow => "ờ",
                .uoz => "uồ",
                .uaz => "uầ",
                .uaw => "ừa",
                .uez => "uề",
                .az => "ầ",
                .ez => "ề",
                .oz => "ồ",
                .iez => "iề",
                .yez => "yề",
                .uyez => "uyề",
                .uow => "ườ",
                .a => "à",
                .e => "è",
                .i => "ì",
                .u => "ù",
                .y => "ỳ",
                .o => "ò",
                .ua => "ùa",
                .ia => "ìa",
                .oa => "oà",
                .oe => "oè",
                .ooo => "oò",
                .uy => "uỳ",
                else => @tagName(self.am_giua),
            },
            .r => switch (self.am_giua) {
                ._none => blank,
                .oaw => "oẳ",
                .aw => "ẳ",
                .uw => "ử",
                .ow => "ở",
                .uoz => "uổ",
                .uaz => "uẩ",
                .uaw => "ửa",
                .uez => "uể",
                .az => "ẩ",
                .ez => "ể",
                .oz => "ổ",
                .iez => "iể",
                .yez => "yể",
                .uyez => "uyể",
                .uow => "ưở",
                .a => "ả",
                .e => "ẻ",
                .i => "ỉ",
                .u => "ủ",
                .y => "ỷ",
                .o => "ỏ",
                .ua => "ủa",
                .ia => "ỉa",
                .oa => "oả",
                .oe => "oẻ",
                .ooo => "oỏ",
                .uy => "uỷ",
                else => @tagName(self.am_giua),
            },
            .x => switch (self.am_giua) {
                ._none => blank,
                .oaw => "oẵ",
                .aw => "ẵ",
                .uw => "ữ",
                .ow => "ỡ",
                .uoz => "uỗ",
                .uaz => "uẫ",
                .uaw => "ữa",
                .uez => "uễ",
                .az => "ẫ",
                .ez => "ễ",
                .oz => "ỗ",
                .iez => "iễ",
                .yez => "yễ",
                .uyez => "uyễ",
                .uow => "ưỡ",
                .a => "ã",
                .e => "ẽ",
                .i => "ĩ",
                .u => "ũ",
                .y => "ỹ",
                .o => "õ",
                .ua => "ũa",
                .ia => "ĩa",
                .oa => "oã",
                .oe => "oẽ",
                .ooo => "oõ",
                .uy => "uỹ",
                else => @tagName(self.am_giua),
            },
            .j => switch (self.am_giua) {
                ._none => blank,
                .oaw => "oặ",
                .aw => "ặ",
                .uw => "ự",
                .ow => "ợ",
                .uoz => "uộ",
                .uaz => "uậ",
                .uaw => "ựa",
                .uez => "uệ",
                .az => "ậ",
                .ez => "ệ",
                .oz => "ộ",
                .iez => "iệ",
                .yez => "yệ",
                .uyez => "uyệ",
                .uow => "ượ",
                .a => "ạ",
                .e => "ẹ",
                .i => "ị",
                .u => "ụ",
                .y => "ỵ",
                .o => "ọ",
                .ua => "ụa",
                .ia => "ịa",
                .oa => "oạ",
                .oe => "oẹ",
                .ooo => "oọ",
                .uy => "uỵ",
                else => @tagName(self.am_giua),
            },
        };

        const cuoi = if (self.am_cuoi == ._none) blank else @tagName(self.am_cuoi);

        std.debug.assert(buff.len >= dau.len + giua.len + cuoi.len);

        var n: usize = 0;
        const parts: [3][]const u8 = .{ dau, giua, cuoi };

        for (parts) |s| {
            for (s) |b| {
                buff[n] = b;
                n += 1;
            }
        }
        return buff[0..n];
    }

    pub fn len(self: Syllable) u8 {
        return self.am_dau.len() + self.am_giua.len() + self.am_cuoi.len() + self.tone.len();
    }
    pub fn hasAmDem(self: Syllable) bool {
        return self.am_giua.hasAmDem() || self.am_dau == .qu;
    }
    pub fn isSaturated(self: Syllable) bool {
        return self.am_cuoi.isSaturated() and self.tone.isSaturated();
    }
};

test "Syllable's printBuff" {
    var syll = Syllable{
        .am_dau = AmDau.ng,
        .am_giua = AmGiua.uaw,
        .am_cuoi = AmCuoi._none,
        .tone = Tone.s,
        .can_be_vietnamese = true,
    };

    var buffer: [15]u8 = undefined;
    const buff = buffer[0..];

    try std.testing.expectEqualStrings(syll.printBuffTelex(buff), "nguwas");
    try std.testing.expectEqualStrings(syll.printBuffUtf8(buff), "ngứa");
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "_ng uaw s");

    syll.am_giua = .o;
    try std.testing.expectEqualStrings(syll.printBuffTelex(buff), "ngos");
    try std.testing.expectEqualStrings(syll.printBuffUtf8(buff), "ngó");
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "_ng o s");

    syll.am_giua = .iez;
    syll.am_cuoi = .n;
    try std.testing.expectEqualStrings(syll.printBuffTelex(buff), "ngieens");
    try std.testing.expectEqualStrings(syll.printBuffUtf8(buff), "ngiến");
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "_ng iez n s");

    syll.am_giua = .o;
    syll.tone = ._none;
    syll.am_cuoi = ._none;
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "_ng o");

    syll.am_giua = .oz;
    syll.am_cuoi = .n;
    try std.testing.expectEqualStrings(syll.printBuffTelex(buff), "ngoon");
    try std.testing.expectEqualStrings(syll.printBuffUtf8(buff), "ngôn");
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "_ng oz n");

    syll.am_dau = .qu;
    syll.am_giua = .a;
    syll.am_cuoi = .n;
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "_q ua n");

    syll.am_dau = .ngh;
    syll.am_giua = .ooo;
    syll.am_cuoi = .ng;
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "_ng oo ng");

    syll.am_dau = .gh;
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "_g oo ng");
}
