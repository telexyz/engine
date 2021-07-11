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
    q,
    r,
    s,
    t,
    v,
    x,
    ch,
    dd,
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
            1...16 => 1,
            17...27 => 2,
            28 => 3,
            else => 0,
        };
    }
    pub fn isSaturated(self: AmDau) bool {
        if (self.len() == 3) return true;
        if (self.len() == 2 and self != .ng) return true;
        if (self.len() == 1) {
            switch (self) {
                .c, .d, .g, .k, .n, .p, .q, .t => {
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
            .dd => .d,
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
    try expect(AmDau.dd.isSaturated() == true);
}

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
/// - Các nguyên âm đôi : Có 3 nguyên âm đôi và được tách thành 8 nguyên âm sau:
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
    uo, // <= 'uoo', 'uow', 'uwow', without mark, 'uo' must followed by z tone
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

    // uow, // “thuở/thủa” => convert to "ủa" ?/
    // http://repository.ulis.vnu.edu.vn/handle/ULIS_123456789/164

    pub fn startWithIY(self: AmGiua) bool {
        return switch (self) {
            .i, .y, .ia, .iez, .yez => true,
            else => false,
        };
    }
    pub fn hasMark(self: AmGiua) bool {
        return switch (self) {
            .az, .aw, .ez, .uw, .oz, .ow, .oaw, .uaz, .uez, .uoz, .uaw, .iez, .yez, .uyez => true,
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
    am_dau: AmDau,
    am_giua: AmGiua,
    am_cuoi: AmCuoi,
    tone: Tone,
    can_be_vietnamese: bool,
    // buffer: [11]u8 = undefined,

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

    pub fn printBuff(self: *Syllable, buff: []u8) []const u8 {
        const blank = "";
        const dau = if (self.am_dau == ._none) blank else @tagName(self.am_dau);
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

    var buffer: [11]u8 = undefined;
    const buff = buffer[0..];

    try std.testing.expectEqualStrings(syll.printBuff(buff), "nguwas");

    syll.am_giua = .o;
    try std.testing.expectEqualStrings(syll.printBuff(buff), "ngos");

    syll.am_giua = .iez;
    syll.am_cuoi = .n;
    try std.testing.expectEqualStrings(syll.printBuff(buff), "ngieens");

    syll.am_giua = .oz;
    syll.am_cuoi = .n;
    syll.tone = ._none;
    try std.testing.expectEqualStrings(syll.printBuff(buff), "ngoon");
}
