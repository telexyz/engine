const std = @import("std");
const expect = std.testing.expect;
const fmt = std.fmt;

// Ref https://tieuluan.info/ti-liu-bdhsg-mn-ting-vit-lp-4-5.html?page=11
// - 22 phụ âm: b, c (k,q), ch, d, đ, g (gh), h, kh, l, m, n, nh, ng (ngh),
// p, ph, r, s, t, tr, th, v, x. (+ qu, gi, _none => 25)

pub const AmDau = enum {
    // 25 âm đầu
    _none,
    b, // 1th
    c, // Viết thành k trước các nguyên âm e, ê, i (iê, ia)
    // Cần kiểm tra từ vay mượn Bắc Kạn
    d,
    g,
    h,
    l,
    m,
    n,
    p,
    r, // 10th
    s,
    t,
    v,
    x,
    ch,
    zd, // âm đ
    gi, // dùng như âm d, `gì` viết đúng, đủ là `giì`, đọc là `dì`
    kh,
    ng,
    nh, // 20th
    ph,
    qu, // q chỉ đi với + âm đệm u, `qu` là 1 âm độc lập
    th,
    tr, // 24th
    // Transit states: gh, ngh trước các nguyên âm e, ê, i, iê (ia).
    gh, // => g
    ngh, // ng

    pub fn len(self: AmDau) u8 {
        return switch (@enumToInt(self)) {
            0 => 0,
            1...14 => 1,
            26 => 3,
            else => 2,
        };
    }
    pub fn isSaturated(self: AmDau) bool {
        return switch (self) {
            .c, .d, .g, .n, .p, .t, ._none, .ng => false,
            else => return true,
        };
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
    try expect(AmDau._none.len() == 0);
    try expect(AmDau._none.isSaturated() == false);
    try expect(AmDau.zd.isSaturated() == true);
}

// https://tieuluan.info/ti-liu-bdhsg-mn-ting-vit-lp-4-5.html?page=12
// 2. Vần gồm có 3 phần: âm đệm, âm chính, âm cuối.
// - Âm đệm được ghi bằng con chữ u và o.
//     + Ghi bằng con chữ o khi đứng trước các nguyên âm: a, ă, e.
//     + Ghi bằng con chữ u khi đứng trước các nguyên âm y, ê, ơ, â.
//
// - Âm đệm không xuất hiện sau các phụ âm b, m, v, ph, n, r, g. Trừ các trường hợp:
//     + sau ph, b: thùng phuy, voan, ô tô buýt (là từ nước ngoài)
//     + sau n: thê noa, noãn sào (2 từ Hán Việt)
//     + sau r: roàn roạt (1 từ)
//     + sau g: goá (1 từ)
//
// Trong Tiếng Việt, nguyên âm nào cũng có thể làm âm chính của tiếng.
// - Các nguyên âm đơn: (11 nguyên âm ghi ở trên)
//
// - Các nguyên âm đôi: Có 3 nguyên âm đôi và được tách thành 8 nguyên âm sau:
//
// * iê:
//   - Ghi bằng ia khi phía trước không có âm đệm và phía sau không có âm cuối
//     (VD: mía, tia, kia,...)
//   - Ghi bằng yê khi phía trước có âm đệm hoặc không có âm nào, phía sau có âm cuối
//     (VD: yêu, chuyên,...)
//   - Ghi bằng ya khi phía trước có âm đệm và phía sau không có âm cuối (VD: khuya...)
//   - Ghi bằng iê khi phía trước có phụ âm đầu, phía sau có âm cuối (VD: tiên, kiến...)
//
// + uơ:
//   - Ghi bằng ươ khi sau nó có âm cuối ( VD: mượn,...)
//   - Ghi bằng ưa khi phía sau nó không có âm cuối (VD: mưa,...)
//
// + uô:
//   - Ghi bằng uô khi sau nó có âm cuối (VD: muốn,...)
//   - Ghi bằng ua khi sau nó không có âm cuối (VD: mua,...)

pub const AmGiua = enum {
    // 23 âm giữa (âm đệm + nguyên âm)
    a, // 0th
    e,
    i,
    o,
    u,
    y, // nhập làm một với i? í ới, người í, người Ý, người ý ??? => ko nên

    az, // â
    aw, // ă
    ez, // ê
    oz, // ô
    ow, // ơ
    uw, // ư 11th

    oa,
    oe,
    ooo,
    uy, // boong 15th

    iez, // iê <= ie (tiên <= tien, tieen, tiezn)
    oaw, // oă
    uaz, // uâ (ngoe nguẩy <= ngoẩy)
    uez, // uê <= ue (tuê =< tue, tuee, tuez)
    uoz, // uô

    uow, //  uwow, ươ 21th
    uyez, // uyez, uyê <= uye (nguyên <= nguyen, nguyeen, nguyezn)

    // Transit states
    ua, // => uoz
    ia, // => iez
    uaw, // ưa => ươ
    uya, // => uyez
    _none, // none chỉ để đánh dấu chưa parse, sau bỏ đi

    // “thuở/thủa” => convert to "ủa" nếu muốn chuẩn hoá
    // http://repository.ulis.vnu.edu.vn/handle/ULIS_123456789/164
    // Về việc hiển thị và bộ gõ thì ko cần convert vì thuở sẽ ko đi cùng âm cuối,
    // và ngược lại ươ ko đứng riêng mà cần âm cuối đi kèm.

    pub fn normalize(self: AmGiua) AmGiua {
        return switch (self) {
            .ua => .uoz,
            .ia => .iez,
            .uaw => .uow,
            .uya => .uyez,
            else => self,
        };
    }

    pub fn startWithIY(self: AmGiua) bool {
        return switch (self) {
            .i, .y, .ia, .iez => true,
            else => false,
        };
    }
    pub fn hasMark(self: AmGiua) bool {
        return switch (self) {
            .az, .aw, .ez, .uw, .oz, .ow, .oaw, .uaz, .uez, .uow, .uoz, .uaw, .iez, .uyez => true,
            else => false,
        };
    }
    pub fn len(self: AmGiua) u8 {
        switch (@enumToInt(self)) {
            0...5 => return 1,
            6...15 => return 2,
            16...20 => return 3,
            21, 22 => return 4,
            else => switch (self) {
                .ua, .ia => return 2,
                .uaw, .uya => return 3,
                else => return 0,
            },
        }
    }
    pub fn isSaturated(self: AmGiua) bool {
        if (self.len() == 4 or self.len() == 3) return true;
        if (self.len() == 2) {
            switch (self) {
                .oa, .ooo, .ua, .uw, .uy => { // .uo,
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
            .uaz, .uez, .uy, .uyez, .uya => true,
            .oa, .oaw, .oe, .ooo => true,
            else => false,
        };
    }
};

test "Enum AmGiua" {
    try expect(AmGiua.a.len() == 1);
    try expect(AmGiua.y.len() == 1);
    try expect(AmGiua.az.len() == 2);
    try expect(AmGiua.uy.len() == 2);
    try expect(AmGiua.iez.len() == 3);
    try expect(AmGiua.uya.len() == 3);
    try expect(AmGiua.uow.len() == 4);
    try expect(AmGiua.uyez.len() == 4);
    try expect(AmGiua._none.len() == 0);
}

/// * Âm cuối:
/// - Các phụ âm cuối vần : p, t, c (ch), m, n, ng (nh)
/// - 2 bán âm cuối vần : i (y), u (o)
pub const AmCuoi = enum {
    // 13 âm cuối
    _none, // 0
    i,
    u,
    m,
    n, // 4
    ng,
    nh,
    ch, // 7
    c,
    p,
    t, // 10
    y,
    o,
    pub fn len(self: AmCuoi) u8 {
        return switch (@enumToInt(self)) {
            0 => 0,
            5...7 => 2,
            else => 1,
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
    // 6 thanh
    _none,
    f,
    r,
    x,
    s,
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

pub const Syllable = struct {
    am_dau: AmDau,
    am_giua: AmGiua,
    am_cuoi: AmCuoi,
    tone: Tone,
    can_be_vietnamese: bool,
    normalized: bool = false,

    pub const UniqueId = u16;

    pub const NONE_ID: UniqueId = 0xffff;

    pub inline fn hasMark(self: Syllable) bool {
        return self.am_dau == .zd or self.am_giua.hasMark();
    }

    pub inline fn hasTone(self: Syllable) bool {
        return self.tone != ._none;
    }

    pub inline fn hasMarkOrTone(self: Syllable) bool {
        return self.hasMark() or self.hasTone();
    }

    pub fn normalize(self: *Syllable) void {
        // std.debug.print("\n!!!! normalizing !!!!\n", .{});
        if (self.normalized) return;

        self.am_giua = self.am_giua.normalize();

        switch (self.am_dau) {
            .gi => {
                if (self.am_giua == .ez and self.am_cuoi != ._none)
                    self.am_giua = .iez;
            },
            .ngh => self.am_dau = .ng, // ngh => ng
            .gh => self.am_dau = .g, // gh => g
            else => {
                if (self.am_dau == .g and self.am_giua == .i) self.am_dau = .gi;
                // gì => gi+ì, gìm => gi+ìm
                // phân biệt gì ghì, gìm ghìm
                // https://vtudien.com/viet-viet/dictionary/nghia-cua-tu-gìm
                // https://vtudien.com/viet-viet/dictionary/nghia-cua-tu-ghìm
            },
        }

        self.normalized = true;
    }

    pub fn toId(self: *Syllable) UniqueId {
        std.debug.assert(self.normalized);
        var am_giua = self.am_giua;
        var am_cuoi = self.am_cuoi;
        //  a  y =>  aw i
        //  az y =>  az i
        // oa  y => oaw i
        // uaz y => uaz i
        if (am_cuoi == .y) {
            am_cuoi = .i;
            if (am_giua == .a) am_giua = .aw;
            if (am_giua == .oa) am_giua = .oaw;
        }
        //  a o => aw u
        //  e o =>  e u
        // oa o => oa u
        // oe o => oe u
        if (am_cuoi == .o) {
            am_cuoi = .u;
            if (am_giua == .a) am_giua = .aw;
        }

        const id =
            (@intCast(UniqueId, @enumToInt(self.am_dau)) << 11) | // u16 <= u5 + u11
            (@intCast(UniqueId, @enumToInt(am_giua)) << 6); //        u5 + u6 => u11

        const am_cuoi_id = @intCast(UniqueId, @enumToInt(am_cuoi));
        const tone = @intCast(UniqueId, @enumToInt(self.tone));

        const act = if (am_cuoi_id < 7)
            am_cuoi_id * 6 + tone
        else // am_cuoi `c, ch, p, t` only 2 tone s, j allowed
            42 + (am_cuoi_id - 7) * 2 + (tone - 4);

        return id + act;
    }

    pub fn newFromId(id: UniqueId) Syllable {
        var x = id >> 6; // get rid first 6-bits of am_cuoi + tone
        var syllable = Syllable{
            .am_dau = @intToEnum(AmDau, @truncate(u5, x >> 5)),
            .am_giua = @intToEnum(AmGiua, @truncate(u5, x)),
            .can_be_vietnamese = true,
            .am_cuoi = ._none,
            .tone = ._none,
        };
        x = @truncate(u6, id); // am_cuoi + tone is last 6-bits value
        if (x < 42) {
            syllable.am_cuoi = @intToEnum(AmCuoi, @truncate(u4, x / 6));
            syllable.tone = @intToEnum(Tone, @truncate(u3, @rem(x, 6)));
        } else { // unpacking
            x -= 42;
            syllable.am_cuoi = @intToEnum(AmCuoi, @truncate(u4, x / 2 + 7));
            syllable.tone = @intToEnum(Tone, @truncate(u3, @rem(x, 2) + 4));
        }

        //  a  y <=  aw i
        //  az y <=  az i
        // oa  y <= oaw i
        // uaz y <= uaz i
        if (syllable.am_cuoi == .i) switch (syllable.am_giua) {
            .aw => {
                syllable.am_cuoi = .y;
                syllable.am_giua = .a;
            },
            .oaw => {
                syllable.am_cuoi = .y;
                syllable.am_giua = .oa;
            },
            .az, .uaz => syllable.am_cuoi = .y,
            else => {},
        };
        //  a o <= aw u
        //  e o <=  e u
        // oa o <= oa u
        // oe o <= oe u
        if (syllable.am_cuoi == .u) switch (syllable.am_giua) {
            .aw => {
                syllable.am_cuoi = .o;
                syllable.am_giua = .a;
            },
            .e, .oa, .oe => syllable.am_cuoi = .o,
            else => {},
        };

        return syllable;
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

    //
    pub fn printBuff(self: *Syllable, buff: []u8, spare: bool) []const u8 {
        const blank = "";
        const giua = switch (self.am_giua) {
            .uow => if (self.am_cuoi == ._none) "uaw" else "uow",
            .uoz => if (self.am_cuoi == ._none) "ua" else "uoz",
            .ooo => "oo",
            .iez => blk: {
                if (self.am_cuoi == ._none) break :blk "ia";
                if (self.am_dau == ._none or self.am_dau == .qu) break :blk "yez";
                break :blk "iez";
            },
            .uyez => if (self.am_cuoi == ._none) "uya" else "uyez",
            else => @tagName(self.am_giua),
        };
        const dau = switch (self.am_dau) {
            ._none => blank,
            .zd => if (spare) "d d" else "dd",
            .c => switch (giua[0]) {
                'e', 'i', 'y' => "k",
                else => "c",
            },
            .gi => if (giua[0] == 'i') "g" else "gi",
            .g => switch (giua[0]) {
                'e', 'i', 'y' => "gh",
                else => "g",
            },
            .ng => switch (giua[0]) {
                'e', 'i', 'y' => "ngh",
                else => "ng",
            },
            else => @tagName(self.am_dau),
        };
        const cuoi = switch (self.am_cuoi) {
            ._none => blank,
            else => @tagName(self.am_cuoi),
        };

        var n: usize = 0;
        var mark: u8 = 0;
        // dau
        for (dau) |byte| {
            buff[n] = byte;
            n += 1;
        }
        // giua
        for (giua) |byte| switch (byte) {
            'w', 'z' => mark = byte,
            else => {
                buff[n] = byte;
                n += 1;
            },
        };
        // cuoi
        for (cuoi) |byte| {
            buff[n] = byte;
            n += 1;
        }
        // ngăn cách với mark+tone
        buff[n] = if (spare) ' ' else '|';
        n += 1;
        // mark
        if (mark != 0) {
            buff[n] = mark;
            n += 1;
        }
        // tone
        if (self.tone != ._none) {
            buff[n] = @tagName(self.tone)[0];
            n += 1;
        }
        // remove ending space for spare mode
        if (buff[n - 1] == 32) n -= 1;

        return buff[0..n];
    }

    pub fn printBuffParts(self: *Syllable, buff: []u8) []const u8 {
        const blank = "";
        // n(dau) = 22 (25 - 3 (_none, gi, qu))
        const dau = switch (self.am_dau) {
            ._none => blank,
            .zd => "dd",
            .gi => "d",
            .qu => "cu", // ok: qua sẽ được convert thành coa
            else => @tagName(self.am_dau),
        };
        // n(giua) = 22 (23 - 1)
        const giua = switch (self.am_giua) {
            .ooo => "oo",
            .iez => "yez",
            .i => "y",
            .a => if (self.am_cuoi == .y or self.am_cuoi == .o) "aw" else "a",
            .oa => if (self.am_cuoi == .y) "oaw" else "oa",
            else => @tagName(self.am_giua),
        };
        // n(cuoi) = 10 (13 - 3 (_none, o, y))
        const cuoi = switch (self.am_cuoi) {
            .o => "u",
            .y => "i",
            ._none => blank,
            else => @tagName(self.am_cuoi),
        };

        // => n(parts) = 58 (22 + 22 + (10-1) + 5 (tones)) => u6
        // 10-1: trùng âm cuối `u` với âm giữa `u`
        var n: usize = 0;

        // dau
        if (dau.len > 0) {
            buff[n] = '_';
            n += 1;
            for (dau) |byte| {
                buff[n] = byte;
                n += 1;
            }
            buff[n] = 32;
            n += 1;
        }

        // giua
        if (giua.len > 0) {
            if (n > 1 and buff[n - 2] == 'u') { // qu => q u
                buff[n - 2] = 32;
                buff[n - 1] = if (giua.len == 1 and giua[0] == 'a') 'o' else 'u';
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
        const giua = switch (self.am_giua) {
            ._none => blank,
            .uoz => if (self.am_cuoi == ._none) "ua" else "uoo",
            .uow => if (self.am_cuoi == ._none) "uaw" else "uow",
            .uaz => "uaa",
            .uaw => "uwa",
            .uez => "uee",
            .az => "aa",
            .ez => "ee",
            .oz => "oo",
            // .iez => if (self.am_dau == ._none or self.am_dau == .qu) "yee" else "iee",
            // .uyez => "uyee",
            .iez => blk: {
                if (self.am_cuoi == ._none) break :blk "ia";
                if (self.am_dau == ._none or self.am_dau == .qu) break :blk "yee";
                break :blk "iee";
            },
            .uyez => if (self.am_cuoi == ._none) "uya" else "uyee",
            else => @tagName(self.am_giua),
        };
        const dau = switch (self.am_dau) {
            ._none => blank,
            .zd => "dd",
            .c => switch (giua[0]) {
                'e', 'i', 'y' => "k",
                else => "c",
            },
            .gi => if (giua[0] == 'i') "g" else "gi",
            .g => switch (giua[0]) {
                'e', 'i', 'y' => "gh",
                else => "g",
            },
            .ng => switch (giua[0]) {
                'e', 'i', 'y' => "ngh",
                else => "ng",
            },
            else => @tagName(self.am_dau),
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
            .c => switch (@tagName(self.am_giua)[0]) {
                'e', 'i', 'y' => "k",
                else => "c",
            },
            .gi => if (@tagName(self.am_giua)[0] == 'i') "g" else "gi",
            .g => switch (@tagName(self.am_giua)[0]) {
                'e', 'i', 'y' => "gh",
                else => "g",
            },
            .ng => switch (@tagName(self.am_giua)[0]) {
                'e', 'i', 'y' => "ngh",
                else => "ng",
            },
            else => @tagName(self.am_dau),
        };
        const giua = switch (self.tone) {
            ._none => switch (self.am_giua) {
                ._none => blank,
                .oaw => "oă",
                .aw => "ă",
                .uw => "ư",
                .ow => "ơ",
                .uoz => if (self.am_cuoi == ._none) "ua" else "uô",
                .uow => if (self.am_cuoi == ._none) "ưa" else "ươ",
                .uaz => "uâ",
                .uaw => "ưa",
                .uez => "uê",
                .az => "â",
                .ez => "ê",
                .oz => "ô",
                .iez => blk: {
                    if (self.am_cuoi == ._none) break :blk "ia";
                    if (self.am_dau == ._none or self.am_dau == .qu) break :blk "yê";
                    break :blk "iê";
                },
                .uyez => if (self.am_cuoi == ._none) "uya" else "uyê",
                .ooo => "oo",
                else => @tagName(self.am_giua),
            },
            .s => switch (self.am_giua) {
                ._none => blank,
                .oaw => "oắ",
                .aw => "ắ",
                .uw => "ứ",
                .ow => "ớ",
                .uoz => if (self.am_cuoi == ._none) "úa" else "uố",
                .uow => if (self.am_cuoi == ._none) "ứa" else "ướ",
                .uaz => "uấ",
                .uaw => "ứa",
                .uez => "uế",
                .az => "ấ",
                .ez => "ế",
                .oz => "ố",
                .iez => blk: {
                    if (self.am_cuoi == ._none) break :blk "ía";
                    if (self.am_dau == ._none or self.am_dau == .qu) break :blk "yế";
                    break :blk "iế";
                },
                .uyez => if (self.am_cuoi == ._none) "uýa" else "uyế",
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
                .uoz => if (self.am_cuoi == ._none) "ùa" else "uồ",
                .uow => if (self.am_cuoi == ._none) "ừa" else "ườ",
                .uaz => "uầ",
                .uaw => "ừa",
                .uez => "uề",
                .az => "ầ",
                .ez => "ề",
                .oz => "ồ",
                .iez => blk: {
                    if (self.am_cuoi == ._none) break :blk "ìa";
                    if (self.am_dau == ._none or self.am_dau == .qu) break :blk "yề";
                    break :blk "iề";
                },
                .uyez => if (self.am_cuoi == ._none) "uỳa" else "uyề",
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
                .uoz => if (self.am_cuoi == ._none) "ủa" else "uổ",
                .uow => if (self.am_cuoi == ._none) "ửa" else "ưở",
                .uaz => "uẩ",
                .uaw => "ửa",
                .uez => "uể",
                .az => "ẩ",
                .ez => "ể",
                .oz => "ổ",
                .iez => blk: {
                    if (self.am_cuoi == ._none) break :blk "ỉa";
                    if (self.am_dau == ._none or self.am_dau == .qu) break :blk "yể";
                    break :blk "iể";
                },
                .uyez => if (self.am_cuoi == ._none) "uỷa" else "uyể",
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
                .uoz => if (self.am_cuoi == ._none) "ũa" else "uỗ",
                .uow => if (self.am_cuoi == ._none) "ữa" else "ưỡ",
                .uaz => "uẫ",
                .uaw => "ữa",
                .uez => "uễ",
                .az => "ẫ",
                .ez => "ễ",
                .oz => "ỗ",
                .iez => blk: {
                    if (self.am_cuoi == ._none) break :blk "ĩa";
                    if (self.am_dau == ._none or self.am_dau == .qu) break :blk "yễ";
                    break :blk "iễ";
                },
                .uyez => if (self.am_cuoi == ._none) "uỹa" else "uyễ",
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
                .uoz => if (self.am_cuoi == ._none) "ụa" else "uộ",
                .uow => if (self.am_cuoi == ._none) "ựa" else "ượ",
                .uaz => "uậ",
                .uaw => "ựa",
                .uez => "uệ",
                .az => "ậ",
                .ez => "ệ",
                .oz => "ộ",
                .iez => blk: {
                    if (self.am_cuoi == ._none) break :blk "ịa";
                    if (self.am_dau == ._none or self.am_dau == .qu) break :blk "yệ";
                    break :blk "iệ";
                },
                .uyez => if (self.am_cuoi == ._none) "uỵa" else "uyệ",
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
    try std.testing.expectEqualStrings(syll.printBuffTelex(buff), "nghieens");
    try std.testing.expectEqualStrings(syll.printBuffUtf8(buff), "nghiến");
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "_ng yez n s");

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
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "_c oa n");

    syll.am_dau = .ng;
    syll.am_giua = .ooo;
    syll.am_cuoi = .ng;
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "_ng oo ng");

    syll.am_dau = .gh;
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "_gh oo ng");

    syll.am_dau = ._none;
    syll.am_giua = .iez;
    syll.am_cuoi = .u;
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "yez u");

    syll.am_giua = .i;
    syll.am_cuoi = ._none;
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "y");

    syll.am_dau = ._none;
    syll.am_giua = .iez;
    syll.am_cuoi = .u;
    syll.tone = .s;
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "yez u s");

    syll.am_dau = .qu;
    syll.am_giua = .iez;
    syll.am_cuoi = .n;
    syll.tone = .f;
    try std.testing.expectEqualStrings(syll.printBuffParts(buff), "_c uyez n f");

    syll.am_dau = ._none;
    syll.am_giua = .a;
    syll.am_cuoi = ._none;
    syll.tone = ._none;
    try std.testing.expectEqualStrings(syll.printBuff(buff, false), "a|");
}
