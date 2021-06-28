const std = @import("std");
const testing = std.testing;
const expect = testing.expect;
const print = std.debug.print;
const unicode = std.unicode;

const syllable_data_structs = @import("syllable_data_structs.zig");

const IS_UPPER = 512;

pub inline fn utf8ToTelexCode(char: u21, first_byte: u8) u10 {
    var am_giua: syllable_data_structs.AmGiua = ._none;
    var tone: syllable_data_structs.Tone = ._none;
    var telex_code: u10 = 0;
    var upper_code: u10 = 0;

    // first_byte == 0 mean don't know it's value
    // Need to try every possibility
    if (first_byte == 195 or first_byte == 0)
        switch (char) {
            'à' => {
                tone = .f;
                telex_code = 'a' - 83;
            },
            'á' => {
                tone = .s;
                telex_code = 'a' - 83;
            },
            'â' => {
                am_giua = .aa;
            },
            'ã' => {
                tone = .x;
                telex_code = 'a' - 83;
            },
            'è' => {
                tone = .f;
                telex_code = 'e' - 83;
            },
            'é' => {
                tone = .s;
                telex_code = 'e' - 83;
            },
            'ê' => {
                am_giua = .ee;
            },
            'ì' => {
                tone = .f;
                telex_code = 'i' - 83;
            },
            'í' => {
                tone = .s;
                telex_code = 'i' - 83;
            },
            'ò' => {
                tone = .f;
                telex_code = 'o' - 83;
            },
            'ó' => {
                tone = .s;
                telex_code = 'o' - 83;
            },
            'ô' => {
                am_giua = .oo;
            },
            'õ' => {
                tone = .x;
                telex_code = 'o' - 83;
            },
            'ù' => {
                tone = .f;
                telex_code = 'u' - 83;
            },
            'ú' => {
                tone = .s;
                telex_code = 'u' - 83;
            },
            'ý' => {
                tone = .s;
                telex_code = 'y' - 83;
            },

            'À' => {
                tone = .f;
                telex_code = 'a' - 83;
                upper_code = IS_UPPER;
            },
            'Á' => {
                tone = .s;
                telex_code = 'a' - 83;
                upper_code = IS_UPPER;
            },
            'Â' => {
                am_giua = .aa;
                upper_code = IS_UPPER;
            },
            'Ã' => {
                tone = .x;
                telex_code = 'a' - 83;
                upper_code = IS_UPPER;
            },
            'È' => {
                tone = .f;
                telex_code = 'e' - 83;
                upper_code = IS_UPPER;
            },
            'É' => {
                tone = .s;
                telex_code = 'e' - 83;
                upper_code = IS_UPPER;
            },
            'Ê' => {
                am_giua = .ee;
                upper_code = IS_UPPER;
            },
            'Ì' => {
                tone = .f;
                telex_code = 'i' - 83;
                upper_code = IS_UPPER;
            },
            'Í' => {
                tone = .s;
                telex_code = 'i' - 83;
                upper_code = IS_UPPER;
            },
            'Ò' => {
                tone = .f;
                telex_code = 'o' - 83;
                upper_code = IS_UPPER;
            },
            'Ó' => {
                tone = .s;
                telex_code = 'o' - 83;
                upper_code = IS_UPPER;
            },
            'Ô' => {
                am_giua = .oo;
                upper_code = IS_UPPER;
            },
            'Õ' => {
                tone = .x;
                telex_code = 'o' - 83;
                upper_code = IS_UPPER;
            },
            'Ù' => {
                tone = .f;
                telex_code = 'u' - 83;
                upper_code = IS_UPPER;
            },
            'Ú' => {
                tone = .s;
                telex_code = 'u' - 83;
                upper_code = IS_UPPER;
            },
            'Ý' => {
                tone = .s;
                telex_code = 'y' - 83;
                upper_code = IS_UPPER;
            },
            else => {
                if (first_byte != 0) return 0;
            },
        };

    if (telex_code == 0 and ((196 <= first_byte and first_byte <= 198) or first_byte == 0))
        switch (char) {
            'ă' => {
                am_giua = .aw;
            },
            'đ' => {
                telex_code = 13;
            },
            'ĩ' => {
                tone = .x;
                telex_code = 'i' - 83;
            },
            'ũ' => {
                tone = .x;
                telex_code = 'u' - 83;
            },
            'ư' => {
                am_giua = .uw;
            },
            'ơ' => {
                am_giua = .ow;
            },
            'Ă' => {
                am_giua = .aw;
                upper_code = IS_UPPER;
            },
            'Đ' => {
                telex_code = 13;
                upper_code = IS_UPPER;
            },
            'Ĩ' => {
                tone = .x;
                telex_code = 'i' - 83;
                upper_code = IS_UPPER;
            },
            'Ũ' => {
                tone = .x;
                telex_code = 'u' - 83;
                upper_code = IS_UPPER;
            },
            'Ư' => {
                am_giua = .uw;
                upper_code = IS_UPPER;
            },
            'Ơ' => {
                am_giua = .ow;
                upper_code = IS_UPPER;
            },
            else => {
                if (first_byte != 0) return 0;
            },
        };

    if (telex_code == 0 and (first_byte == 225 or first_byte == 0))
        switch (char) {
            'ả' => {
                tone = .r;
                telex_code = 'a' - 83;
            },
            'ạ' => {
                tone = .j;
                telex_code = 'a' - 83;
            },
            'ấ' => {
                tone = .s;
                am_giua = .aa;
            },
            'ầ' => {
                tone = .f;
                am_giua = .aa;
            },
            'ẩ' => {
                tone = .r;
                am_giua = .aa;
            },
            'ẫ' => {
                tone = .x;
                am_giua = .aa;
            },
            'ậ' => {
                tone = .j;
                am_giua = .aa;
            },
            'ắ' => {
                tone = .s;
                am_giua = .aw;
            },
            'ằ' => {
                tone = .f;
                am_giua = .aw;
            },
            'ẳ' => {
                tone = .r;
                am_giua = .aw;
            },
            'ẵ' => {
                tone = .x;
                am_giua = .aw;
            },
            'ặ' => {
                tone = .j;
                am_giua = .aw;
            },
            'ẻ' => {
                tone = .r;
                telex_code = 'e' - 83;
            },
            'ẽ' => {
                tone = .x;
                telex_code = 'e' - 83;
            },
            'ẹ' => {
                tone = .j;
                telex_code = 'e' - 83;
            },
            'ế' => {
                tone = .s;
                am_giua = .ee;
            },
            'ề' => {
                tone = .f;
                am_giua = .ee;
            },
            'ể' => {
                tone = .r;
                am_giua = .ee;
            },
            'ễ' => {
                tone = .x;
                am_giua = .ee;
            },
            'ệ' => {
                tone = .j;
                am_giua = .ee;
            },
            'ỳ' => {
                tone = .f;
                telex_code = 'y' - 83;
            },
            'ỷ' => {
                tone = .r;
                telex_code = 'y' - 83;
            },
            'ỹ' => {
                tone = .x;
                telex_code = 'y' - 83;
            },
            'ỵ' => {
                tone = .j;
                telex_code = 'y' - 83;
            },
            'ỉ' => {
                tone = .r;
                telex_code = 'i' - 83;
            },
            'ị' => {
                tone = .j;
                telex_code = 'i' - 83;
            },
            'ủ' => {
                tone = .r;
                telex_code = 'u' - 83;
            },
            'ụ' => {
                tone = .j;
                telex_code = 'u' - 83;
            },
            'ứ' => {
                tone = .s;
                am_giua = .uw;
            },
            'ừ' => {
                tone = .f;
                am_giua = .uw;
            },
            'ử' => {
                tone = .r;
                am_giua = .uw;
            },
            'ữ' => {
                tone = .x;
                am_giua = .uw;
            },
            'ự' => {
                tone = .j;
                am_giua = .uw;
            },
            'ỏ' => {
                tone = .r;
                telex_code = 'o' - 83;
            },
            'ọ' => {
                tone = .j;
                telex_code = 'o' - 83;
            },
            'ố' => {
                tone = .s;
                am_giua = .oo;
            },
            'ồ' => {
                tone = .f;
                am_giua = .oo;
            },
            'ổ' => {
                tone = .r;
                am_giua = .oo;
            },
            'ỗ' => {
                tone = .x;
                am_giua = .oo;
            },
            'ộ' => {
                tone = .j;
                am_giua = .oo;
            },
            'ớ' => {
                tone = .s;
                am_giua = .ow;
            },
            'ờ' => {
                tone = .f;
                am_giua = .ow;
            },
            'ở' => {
                tone = .r;
                am_giua = .ow;
            },
            'ỡ' => {
                tone = .x;
                am_giua = .ow;
            },
            'ợ' => {
                tone = .j;
                am_giua = .ow;
            },

            'Ả' => {
                tone = .r;
                telex_code = 'a' - 83;
                upper_code = IS_UPPER;
            },
            'Ạ' => {
                tone = .j;
                telex_code = 'a' - 83;
                upper_code = IS_UPPER;
            },
            'Ấ' => {
                tone = .s;
                am_giua = .aa;
                upper_code = IS_UPPER;
            },
            'Ầ' => {
                tone = .f;
                am_giua = .aa;
                upper_code = IS_UPPER;
            },
            'Ẩ' => {
                tone = .r;
                am_giua = .aa;
                upper_code = IS_UPPER;
            },
            'Ẫ' => {
                tone = .x;
                am_giua = .aa;
                upper_code = IS_UPPER;
            },
            'Ậ' => {
                tone = .j;
                am_giua = .aa;
                upper_code = IS_UPPER;
            },
            'Ắ' => {
                tone = .s;
                am_giua = .aw;
                upper_code = IS_UPPER;
            },
            'Ằ' => {
                tone = .f;
                am_giua = .aw;
                upper_code = IS_UPPER;
            },
            'Ẳ' => {
                tone = .r;
                am_giua = .aw;
                upper_code = IS_UPPER;
            },
            'Ẵ' => {
                tone = .x;
                am_giua = .aw;
                upper_code = IS_UPPER;
            },
            'Ặ' => {
                tone = .j;
                am_giua = .aw;
                upper_code = IS_UPPER;
            },
            'Ẻ' => {
                tone = .r;
                telex_code = 'e' - 83;
                upper_code = IS_UPPER;
            },
            'Ẽ' => {
                tone = .x;
                telex_code = 'e' - 83;
                upper_code = IS_UPPER;
            },
            'Ẹ' => {
                tone = .j;
                telex_code = 'e' - 83;
                upper_code = IS_UPPER;
            },
            'Ế' => {
                tone = .s;
                am_giua = .ee;
                upper_code = IS_UPPER;
            },
            'Ề' => {
                tone = .f;
                am_giua = .ee;
                upper_code = IS_UPPER;
            },
            'Ể' => {
                tone = .r;
                am_giua = .ee;
                upper_code = IS_UPPER;
            },
            'Ễ' => {
                tone = .x;
                am_giua = .ee;
                upper_code = IS_UPPER;
            },
            'Ệ' => {
                tone = .j;
                am_giua = .ee;
                upper_code = IS_UPPER;
            },
            'Ỳ' => {
                tone = .f;
                telex_code = 'y' - 83;
                upper_code = IS_UPPER;
            },
            'Ỷ' => {
                tone = .r;
                telex_code = 'y' - 83;
                upper_code = IS_UPPER;
            },
            'Ỹ' => {
                tone = .x;
                telex_code = 'y' - 83;
                upper_code = IS_UPPER;
            },
            'Ỵ' => {
                tone = .j;
                telex_code = 'y' - 83;
                upper_code = IS_UPPER;
            },
            'Ỉ' => {
                tone = .r;
                telex_code = 'i' - 83;
                upper_code = IS_UPPER;
            },
            'Ị' => {
                tone = .j;
                telex_code = 'i' - 83;
                upper_code = IS_UPPER;
            },
            'Ủ' => {
                tone = .r;
                telex_code = 'u' - 83;
                upper_code = IS_UPPER;
            },
            'Ụ' => {
                tone = .j;
                telex_code = 'u' - 83;
                upper_code = IS_UPPER;
            },
            'Ứ' => {
                tone = .s;
                am_giua = .uw;
                upper_code = IS_UPPER;
            },
            'Ừ' => {
                tone = .f;
                am_giua = .uw;
                upper_code = IS_UPPER;
            },
            'Ử' => {
                tone = .r;
                am_giua = .uw;
                upper_code = IS_UPPER;
            },
            'Ữ' => {
                tone = .x;
                am_giua = .uw;
                upper_code = IS_UPPER;
            },
            'Ự' => {
                tone = .j;
                am_giua = .uw;
                upper_code = IS_UPPER;
            },
            'Ỏ' => {
                tone = .r;
                telex_code = 'o' - 83;
                upper_code = IS_UPPER;
            },
            'Ọ' => {
                tone = .j;
                telex_code = 'o' - 83;
                upper_code = IS_UPPER;
            },
            'Ố' => {
                tone = .s;
                am_giua = .oo;
                upper_code = IS_UPPER;
            },
            'Ồ' => {
                tone = .f;
                am_giua = .oo;
                upper_code = IS_UPPER;
            },
            'Ổ' => {
                tone = .r;
                am_giua = .oo;
                upper_code = IS_UPPER;
            },
            'Ỗ' => {
                tone = .x;
                am_giua = .oo;
                upper_code = IS_UPPER;
            },
            'Ộ' => {
                tone = .j;
                am_giua = .oo;
                upper_code = IS_UPPER;
            },
            'Ớ' => {
                tone = .s;
                am_giua = .ow;
                upper_code = IS_UPPER;
            },
            'Ờ' => {
                tone = .f;
                am_giua = .ow;
                upper_code = IS_UPPER;
            },
            'Ở' => {
                tone = .r;
                am_giua = .ow;
                upper_code = IS_UPPER;
            },
            'Ỡ' => {
                tone = .x;
                am_giua = .ow;
                upper_code = IS_UPPER;
            },
            'Ợ' => {
                tone = .j;
                am_giua = .ow;
                upper_code = IS_UPPER;
            },
            else => {
                if (first_byte != 0) return 0;
            },
        };

    if (telex_code == 0 and first_byte < 128)
        switch (char) {
            'a'...'z' => {
                // 'a':97=83+14 'z':122=83+39
                telex_code = @truncate(u10, char - 83);
            },

            'A'...'Z' => {
                upper_code = IS_UPPER;
                telex_code = @truncate(u10, char - 51);
            },
            else => {
                if (first_byte != 0) return 0;
            },
        };

    // 0    => invalid
    // 1-6  => nothing
    // 7-12 => nguyên âm đơn có dấu ă,â,ê,ư,ô,ơ
    // 13   => 'đ'
    // 14   => 'a', ..
    // 39   => 'z'
    if (am_giua != ._none) {
        telex_code = @intCast(u10, @enumToInt(am_giua));
    }
    // u10: 1-bit for lower vs upper case
    //      3-bits for tone,
    //      6-bits for telex_code,

    const tone_code = @intCast(u10, @enumToInt(tone)) << 6;
    // print("\n{d} {d} {d}\n", .{ upper_code, tone, telex_code });
    return upper_code +
        tone_code +
        telex_code;
}

test "utf8ToTelexCode()" {
    try expect(getCharByte(utf8ToTelexCode('a', 0)) == 'a');
    try expect(utf8ToTelexCode('A', 0) == 14 + IS_UPPER);
    try expect(utf8ToTelexCode('á', 0) == 14 + (@intCast(u10, @enumToInt(syllable_data_structs.Tone.s)) << 6));
    try expect(utf8ToTelexCode('ổ', 0) == @enumToInt(syllable_data_structs.AmGiua.oo) + (@intCast(u10, @enumToInt(syllable_data_structs.Tone.r)) << 6));

    var telex_code = utf8ToTelexCode('Ẵ', 0);
    try expect(telex_code == @enumToInt(syllable_data_structs.AmGiua.aw) + (@intCast(u10, @enumToInt(syllable_data_structs.Tone.x)) << 6) + IS_UPPER);
    try expect(getToneByte(telex_code) == 'x');
    try expect(isUpper(telex_code));
    try expect(getDoubleBytes(telex_code)[1] == 'w');

    telex_code = utf8ToTelexCode('ụ', 0);
    try expect(getToneByte(telex_code) == 'j');
    try expect(!isUpper(telex_code));
    try expect(getDoubleBytes(telex_code).len == 0);
    try expect(getCharByte(telex_code) == 'u');
}

pub inline fn isUpper(telex_code: u10) bool {
    return telex_code > IS_UPPER;
}

pub inline fn getToneByte(telex_code: u10) u8 {
    return switch (@truncate(u3, telex_code >> 6)) {
        @enumToInt(syllable_data_structs.Tone.s) => 's',
        @enumToInt(syllable_data_structs.Tone.f) => 'f',
        @enumToInt(syllable_data_structs.Tone.r) => 'r',
        @enumToInt(syllable_data_structs.Tone.x) => 'x',
        @enumToInt(syllable_data_structs.Tone.j) => 'j',
        else => 0,
    };
}

pub inline fn getCharByte(telex_code: u10) u8 {
    return @truncate(u8, telex_code & 0b0000111111) + 83;
}

pub inline fn getDoubleBytes(telex_code: u10) []const u8 {
    const am_giua_code = telex_code & 0b0000111111;
    return switch (am_giua_code) {
        13 => "dd",
        @enumToInt(syllable_data_structs.AmGiua.aa) => "aa",
        @enumToInt(syllable_data_structs.AmGiua.aw) => "aw",
        @enumToInt(syllable_data_structs.AmGiua.ee) => "ee",
        @enumToInt(syllable_data_structs.AmGiua.oo) => "oo", // bông
        @enumToInt(syllable_data_structs.AmGiua.ow) => "ow",
        @enumToInt(syllable_data_structs.AmGiua.uw) => "uw",
        else => "",
    };
}

pub inline fn canBeTelexBytes(byte1: u8, byte2: u8) u3 {
    // print("\n{d}-{d}\n", .{ byte1, byte2 });
    if (195 <= byte1 and byte1 <= 198 and
        (128 <= byte2 and byte2 <= 189)) return 2;
    // Xem ascii_telex.md
    if (byte1 == 225 and (byte2 == 186 or byte2 == 187)) return 3;

    // '̀'2:204:128 '́'2:204:129 '̂'2:204:130 '̃'2:204:131
    // '̆'2:204:134 '̉'2:204:137 '̣'2:204:163
    // '̀'2:205:128 '́'2:205:129
    if (byte1 == 204)
        switch (byte2) {
            128...131 => {
                return 2;
            },
            134, 137, 163 => {
                return 2;
            },
            else => {
                return 0;
            },
        };
    if (byte1 == 205 and
        (byte2 == 128 or byte2 == 129)) return 2;
    return 0;
}

test "canBeTelexBytes()" {
    const bytes2 = "đĐÀÁÃÂĂÈÉÊÌÍĨÒÓÕÔƠÝÙÚŨƯàáãâăèéêìíĩòóõôơýùúũư";
    var index: usize = 0;
    while (index < bytes2.len) {
        try expect(canBeTelexBytes(bytes2[index], bytes2[index + 1]) == 2);
        index += 2;
    }
    const bytes3 = "ẦẤẬẨẪẰẮẶẲẴỀẾỆỂỄỒỐỘỔỖỜỚỢỞỠỪỨỰỬỮầấậẩẫằắặẳẵềếệểễồốộổỗờớợởỡừứựửữ";
    index = 0;
    while (index < bytes3.len) {
        try expect(canBeTelexBytes(bytes3[index], bytes3[index + 1]) == 3);
        index += 3;
    }
    const bytes1 = "qwertyuiopdfghjklzxcvbnm";
    index = 0;
    while (index < bytes1.len) {
        try expect(canBeTelexBytes(bytes1[index], bytes1[index + 1]) == 0);
        index += 1;
    }
}
