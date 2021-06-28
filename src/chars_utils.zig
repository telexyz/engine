const telex_utils = @import("telex_utils.zig");

pub const CharStreamError = error{
    OutOfLength,
    InvalidInputChar,
    MarkCharNotFollowAMarkableVowel,
    MoreThanOneTone,
    ToneIsNotFromUtf8,
    MarkIsNotFromUtf8,
    TooBigToBeSyllable,
};

pub const Utf8ToAsciiTelexAmTietCharStream = struct {
    /// The internal character buffer
    /// Max char of an am_tiet is 10
    /// Let say we support maximum 3 syllables, then need 31 bytes
    /// Now support 1 syllable only!
    const MAX_LEN = 10;

    buffer: [MAX_LEN + 1]u8,

    /// Last pushed utf-8 char
    last_char: u21,

    /// Carry the tone to always put it in the end of the stream
    /// tone can only be initialied once
    tone: u8,

    /// len should <= MAX_LEN
    len: usize,

    has_mark: bool,
    pure_utf8: bool,
    is_title_case: bool,
    is_upper_case: bool,

    pub fn new() Utf8ToAsciiTelexAmTietCharStream {
        return .{
            .len = 0,
            .last_char = 0,
            .tone = 0,
            .has_mark = false,
            .buffer = undefined,
            .pure_utf8 = true,
            .is_title_case = false,
            .is_upper_case = true,
        };
    }
    pub fn reset(self: *Utf8ToAsciiTelexAmTietCharStream) void {
        self.len = 0;
        self.last_char = 0;
        self.tone = 0;
        self.has_mark = false;
        self.pure_utf8 = true;
        self.is_title_case = false;
        self.is_upper_case = true;
    }
    pub fn lastCharIsMarkableVowel(self: *Utf8ToAsciiTelexAmTietCharStream) bool {
        return switch (self.buffer[self.len - 1]) {
            'a', 'e', 'u', 'i', 'o' => true,
            else => false,
        };
    }
    pub fn hasMarkOrTone(self: Utf8ToAsciiTelexAmTietCharStream) bool {
        return self.has_mark or self.tone != 0;
    }
    pub fn toStr(self: *Utf8ToAsciiTelexAmTietCharStream) []const u8 {
        // Add tone char at the end if needed
        var n = self.len;
        if (self.tone != 0) {
            self.buffer[n] = self.tone;
            n += 1;
        }

        if (self.is_upper_case) {
            var i: usize = 0;
            while (i < n) : (i += 1) {
                self.buffer[i] &= 0b11011111;
            }
        } else if (self.is_title_case) {
            self.buffer[0] &= 0b11011111;
        }

        return self.buffer[0..n];
    }

    fn pushTelexCode(self: *Utf8ToAsciiTelexAmTietCharStream, telex_code: u10) CharStreamError!void {
        if (telex_code == 0) {
            return CharStreamError.InvalidInputChar;
        }

        if (telex_utils.isUpper(telex_code)) {
            self.is_title_case = (self.len == 0);
        } else {
            self.is_upper_case = false;
        }

        const tone = telex_utils.getToneByte(telex_code);
        if (tone != 0) {
            if (self.tone == 0) {
                self.tone = tone;
            } else {
                return CharStreamError.MoreThanOneTone;
            }
        }

        const buff = telex_utils.getDoubleBytes(telex_code);
        if (buff.len == 2) {
            self.has_mark = true;
            if (self.len + buff.len > MAX_LEN) {
                return CharStreamError.OutOfLength;
            }
            self.buffer[self.len] = buff[0];
            self.len += 1;
            self.buffer[self.len] = buff[1];
            self.len += 1;
        } else {
            self.buffer[self.len] = telex_utils.getCharByte(telex_code);
            self.len += 1;
        }
    }

    pub inline fn pushCharAndFirstByte(self: *Utf8ToAsciiTelexAmTietCharStream, char: u21, first_byte: u8) CharStreamError!void {
        if (self.len >= MAX_LEN) return CharStreamError.OutOfLength;

        // Process can-not-stand-alone char
        // '̀'768, '́'769, '̂'770, '̃'771, '̆'774, '̉'777, '̣'803, '̀'832, '́'833
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
            770 => { //'̂'
                if (!self.lastCharIsMarkableVowel()) return CharStreamError.MarkCharNotFollowAMarkableVowel;
                self.buffer[self.len] = self.buffer[self.len - 1];
                self.len += 1;
                self.has_mark = true;
                self.pure_utf8 = false;
                return;
            },
            774 => { //'̆'
                if (!self.lastCharIsMarkableVowel()) return CharStreamError.MarkCharNotFollowAMarkableVowel;
                self.buffer[self.len] = 'w';
                self.len += 1;
                self.has_mark = true;
                self.pure_utf8 = false;
                return;
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
        // Record can-stand-alone char, and process it
        self.last_char = char;
        try self.pushTelexCode(telex_utils.utf8ToTelexCode(char, first_byte));
    }

    pub inline fn push(self: *Utf8ToAsciiTelexAmTietCharStream, char: u21) CharStreamError!void {
        try self.pushCharAndFirstByte(char, 0);
    }

    pub inline fn pushByte(self: *Utf8ToAsciiTelexAmTietCharStream, byte: u8, is_upper: bool) CharStreamError!void {
        if (self.len >= MAX_LEN) return CharStreamError.OutOfLength;
        self.last_char = @intCast(u21, byte);
        if (is_upper) {
            self.is_title_case = (self.len == 0);
        } else {
            self.is_upper_case = false;
        }
        self.buffer[self.len] = byte;
        self.len += 1;
    }
};

const std = @import("std");
const testing = std.testing;
const expect = testing.expect;
const U2ACharStream = Utf8ToAsciiTelexAmTietCharStream;

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
    try testing.expectEqualStrings(char_stream.toStr(), "as");

    try char_stream.push('A');
    try testing.expectEqualStrings(char_stream.toStr(), "aas");
    try expect(!char_stream.is_title_case);
    try expect(!char_stream.is_upper_case);
    try expect(!char_stream.has_mark);

    try char_stream.push('ô');
    try expect(char_stream.has_mark);

    try char_stream.push('ầ') catch |err| expect(err == CharStreamError.MoreThanOneTone);
}
