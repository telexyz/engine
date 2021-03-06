const telex_utils = @import("telex_utils.zig");

pub const CharStreamError = error{
    OverSize,
    InvalidVowels,
    MoreThanOneTone,
    InvalidInputChar,
    ToneIsNotFromUtf8,
    MarkIsNotFromUtf8,
    TooBigToBeSyllable,
    MarkCharNotFollowAMarkableVowel,
};

pub const Utf8ToAsciiTelexCharStream = struct {
    /// The internal character buffer
    /// Max bytes of an am_tiet is 10
    pub const MAX_LEN = 10; // nguyễng // ễ took 3-bytes
    buffer: [MAX_LEN + 2]u8,

    /// Last pushed utf-8 char
    last_char: u21,

    /// Carry the tone to always put it in the end of the stream
    /// tone can only be initialied once
    tone: u8,

    /// len should <= MAX_LEN
    len: usize,

    has_mark: bool,
    pure_utf8: bool, // has char encoded strangely

    first_char_is_upper: bool,
    upper_chars_count: u8,
    lower_chars_count: u8,

    strict_mode: bool = false,

    pub fn new() Utf8ToAsciiTelexCharStream {
        return .{
            .len = 0,
            .last_char = 0,
            .tone = 0,
            .has_mark = false,
            .buffer = undefined,
            .pure_utf8 = true,
            .first_char_is_upper = false,
            .upper_chars_count = 0,
            .lower_chars_count = 0,
        };
    }
    pub fn reset(self: *Utf8ToAsciiTelexCharStream) void {
        self.len = 0;
        self.last_char = 0;
        self.tone = 0;
        self.has_mark = false;
        self.pure_utf8 = true;
        self.first_char_is_upper = false;
        self.upper_chars_count = 0;
        self.lower_chars_count = 0;
    }
    pub fn hasMarkOrTone(self: Utf8ToAsciiTelexCharStream) bool {
        return self.has_mark or self.tone != 0;
    }

    pub fn isUpper(self: Utf8ToAsciiTelexCharStream) bool {
        return self.len > 1 and self.lower_chars_count == 0;
    }

    pub fn isCapitalized(self: Utf8ToAsciiTelexCharStream) bool {
        return self.first_char_is_upper;
    }

    pub fn hasVowelMark(self: Utf8ToAsciiTelexCharStream) bool {
        return self.has_mark and // but not đ (dd)
            !(self.buffer[0] == 'd' and
            self.buffer[1] == 'd');
    }

    fn pushTelexCode(self: *Utf8ToAsciiTelexCharStream, telex_code: u10) CharStreamError!void {
        if (telex_code == 0) {
            return CharStreamError.InvalidInputChar;
        }

        if (telex_utils.isUpper(telex_code)) {
            if (self.len == 0) self.first_char_is_upper = true;
            self.upper_chars_count += 1;
            //
        } else {
            self.lower_chars_count += 1;
        }

        const tone = telex_utils.getToneByte(telex_code);
        if (tone != 0 and tone != self.tone) {
            if (self.tone == 0) {
                self.tone = tone;
            } else {
                return CharStreamError.MoreThanOneTone;
            }
        }

        const buff = telex_utils.getDoubleBytes(telex_code);

        if (buff.len == 2) {
            self.has_mark = true;

            // Convert uwo{w} => uow, uwa{w} => uaw
            if (self.len > 0 and self.buffer[self.len - 1] == 'w' and (buff[0] == 'o' or buff[0] == 'a')) {
                self.buffer[self.len - 1] = buff[0];
                self.buffer[self.len] = 'w';
                self.len += 1;
                return;
            }

            if (self.len + buff.len > MAX_LEN) {
                return CharStreamError.OverSize;
            }
            self.buffer[self.len] = buff[0];
            self.len += 1;
            self.buffer[self.len] = buff[1];
            self.len += 1;
        } else {
            // buff.len == 1
            const byte = telex_utils.getCharByte(telex_code);

            // Convert uwo{w} => uow
            if (self.len > 0 and self.buffer[self.len - 1] == 'w' and (byte == 'o')) {
                self.buffer[self.len - 1] = byte;
                self.buffer[self.len] = 'w';
                self.len += 1;
            } else {
                self.buffer[self.len] = byte;
                self.len += 1;
            }
        }
    }

    pub inline fn pushCharAndFirstByte(self: *Utf8ToAsciiTelexCharStream, char: u21, first_byte: u8) CharStreamError!void {
        if (self.len >= MAX_LEN) return CharStreamError.OverSize;

        // Process can-not-stand-alone chars
        // '̀'768, '́'769, '̂'770, '̃'771, '̆'774, '̉'777, Ư'795, '̣'803, '̀'832, '́'833
        var tone: u8 = 0;
        switch (char) {
            769, 833 => {
                tone = 's';
            },
            768, 832 => {
                tone = 'f';
            },
            777 => {
                tone = 'r';
            },
            771 => {
                tone = 'x';
            },
            803 => {
                tone = 'j';
            },
            770 => { // â, ê, ô
                if (self.len == 0) return CharStreamError.MarkCharNotFollowAMarkableVowel;
                switch (self.buffer[self.len - 1]) {
                    'a', 'e', 'o' => {
                        self.buffer[self.len] = 'z';
                        self.len += 1;
                        self.has_mark = true;
                        self.pure_utf8 = false;
                        return;
                    },
                    else => {
                        return CharStreamError.MarkCharNotFollowAMarkableVowel;
                    },
                }
            },
            774 => { // ă
                if (self.len == 0) return CharStreamError.MarkCharNotFollowAMarkableVowel;
                switch (self.buffer[self.len - 1]) {
                    'a' => {
                        self.buffer[self.len] = 'w';
                        self.len += 1;
                        self.has_mark = true;
                        self.pure_utf8 = false;
                        return;
                    },
                    'w' => {
                        // Convert uwa{w} => uaw already
                        self.has_mark = true;
                        self.pure_utf8 = false;
                        return;
                    },
                    else => {
                        return CharStreamError.MarkCharNotFollowAMarkableVowel;
                    },
                }
            },
            795 => { // ơ, ư
                if (self.len == 0) return CharStreamError.MarkCharNotFollowAMarkableVowel;
                switch (self.buffer[self.len - 1]) {
                    'u', 'o' => {
                        self.buffer[self.len] = 'w';
                        self.len += 1;
                        self.has_mark = true;
                        self.pure_utf8 = false;
                        return;
                    },
                    'w' => {
                        self.has_mark = true;
                        self.pure_utf8 = false;
                        // Convert uwo{w} => uow already
                        return;
                    },
                    else => {
                        return CharStreamError.MarkCharNotFollowAMarkableVowel;
                    },
                }
            },
            else => {},
        }
        if (tone != 0) {
            self.pure_utf8 = false;
            if (self.tone == 0) {
                self.tone = tone;
                return;
            } else {
                return CharStreamError.MoreThanOneTone;
            }
        }
        // Record only stand-alone char as last_char
        self.last_char = char;

        // if (char == 'ð') std.debug.print("\npushCharAndFirstByte char: `{}`, first_byte: {d}", .{ char, first_byte });

        try self.pushTelexCode(telex_utils.utf8ToTelexCode(char, first_byte));
    }

    pub inline fn push(self: *Utf8ToAsciiTelexCharStream, char: u21) CharStreamError!void {
        try self.pushCharAndFirstByte(char, 0);
    }
};

const std = @import("std");
const testing = std.testing;
const expect = testing.expect;
const U2ACharStream = Utf8ToAsciiTelexCharStream;

test "init()" {
    var char_stream = U2ACharStream.new();
    try expect(char_stream.len == 0);
    try expect(char_stream.last_char == 0);
    // try expect(char_stream.buffer == undefined);
}

test "unrollTone" {
    var char_stream = U2ACharStream.new();
    try char_stream.push('á');
    try expect(char_stream.tone == 's');
    try testing.expectEqualStrings(char_stream.buffer[0..char_stream.len], "a");

    try char_stream.push('A');
    try testing.expectEqualStrings(char_stream.buffer[0..char_stream.len], "aa");
    try expect(!char_stream.isCapitalized());
    try expect(!char_stream.isUpper());
    try expect(!char_stream.has_mark);

    try char_stream.push('ô');
    try expect(char_stream.has_mark);

    try char_stream.push('ầ') catch |err| expect(err == CharStreamError.MoreThanOneTone);
}

test "ưo, uơ, ươ => uow; ưa, uă, ưă => uaw" {
    var char_stream = U2ACharStream.new();
    char_stream.strict_mode = true;

    char_stream.reset();
    try char_stream.push('ư');
    try char_stream.push('o');
    try testing.expectEqualStrings(char_stream.buffer[0..char_stream.len], "uow");

    char_stream.reset();
    try char_stream.push('ư');
    try char_stream.push('ơ');
    try testing.expectEqualStrings(char_stream.buffer[0..char_stream.len], "uow");

    char_stream.reset();
    try char_stream.push('u');
    try char_stream.push('ơ');
    try testing.expectEqualStrings(char_stream.buffer[0..char_stream.len], "uow");

    // ưa, uă, ưă => uaw
    char_stream.reset();
    try char_stream.push('ư');
    try char_stream.push('a');
    try testing.expectEqualStrings(char_stream.buffer[0..char_stream.len], "uwa");

    char_stream.reset();
    try char_stream.push('ư');
    try char_stream.push('ă');
    try testing.expectEqualStrings(char_stream.buffer[0..char_stream.len], "uaw");

    char_stream.reset();
    try char_stream.push('u');
    try char_stream.push('ă');
    try testing.expectEqualStrings(char_stream.buffer[0..char_stream.len], "uaw");
}

test "TAQ => taq" {
    var char_stream = U2ACharStream.new();
    char_stream.strict_mode = true;
    try char_stream.push('T');
    try char_stream.push('A');
    try char_stream.push('Q');
    try testing.expectEqualStrings(char_stream.buffer[0..char_stream.len], "taq");
}

test "strict_mode" {
    var char_stream = U2ACharStream.new();
    char_stream.strict_mode = true;

    try char_stream.push('Đ');
    try testing.expect(!char_stream.hasVowelMark());
    try testing.expect(char_stream.upper_chars_count == 1);
    try char_stream.push('e');
    try testing.expect(char_stream.upper_chars_count == 1);
    try char_stream.push('D');
    try testing.expect(char_stream.buffer[char_stream.len - 1] == 'd');
    //
    char_stream.reset();
    try char_stream.push('E');
    try testing.expect(char_stream.upper_chars_count == 1);
    try testing.expect(!char_stream.hasVowelMark());
    try char_stream.push('Ư');
    try testing.expect(char_stream.upper_chars_count == 2);
    try testing.expect(char_stream.hasVowelMark());
    try char_stream.push('Ơ');
    try testing.expect(char_stream.upper_chars_count == 3);
    try char_stream.push('Ă');
    try testing.expect(char_stream.upper_chars_count == 4);
    try char_stream.push('d');
    //
    char_stream.reset();
    try char_stream.push('ẽ');
    try char_stream.push('D');
    char_stream.reset();
    try char_stream.push('ô');
    char_stream.push('o') catch |err|
        try testing.expect(err == CharStreamError.InvalidVowels);
}
