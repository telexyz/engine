const std = @import("std");
const print = std.debug.print;
const unicode = std.unicode;

// https://www.windmill.co.uk/ascii-control-codes.html
// 8 backspace, 9 \t, 10 \n, \x0b\x0c\x0d
// var str = "|\x00\x01\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0f|";

//\n\tđĐàáãâăèéêìíĩòóõôơýùúũưủụọỏịỉỳỵỷỹạảẹẻẽẦẤẬẨẪẰẮẶẲẴỀẾỆỂỄỒỐỘỔỖỜỚỢỞỠỪỨỰỬỮầấậẩẫằắặẳẵềếệểễồốộổỗờớợởỡừứựửữ";

// var str = "▁ÀÁÂÁẦẤẪẨẦẤẰẮẴẲẰẮẬẶẢǍẠẬÀÁÈÉÊà";

// var str = "qrtpdghklxcvbnm";

var str = "weyuio";

pub fn main() !void {
    print("\n{s}\n\n", .{str});

    var index: usize = undefined;
    var next_index: usize = 0;

    while (next_index < str.len) {
        index = next_index;
        const byte: u8 = str[index];
        const char_bytes_length = unicode.utf8ByteSequenceLength(byte) catch 0;
        next_index = next_index + char_bytes_length;
        print("{d}", .{char_bytes_length});
    }

    print("\n\n", .{});
    next_index = 0;
    while (next_index < str.len) {
        index = next_index;
        const byte: u8 = str[index];
        const char_bytes_length = unicode.utf8ByteSequenceLength(byte) catch 0;
        next_index = next_index + char_bytes_length;
        if (char_bytes_length < 2) continue;
        const char = unicode.utf8Decode(str[index..next_index]);
        print(" '{s}'{d}", .{ str[index..next_index], char });
    }

    print("\n\n", .{});
    next_index = 0;
    while (next_index < str.len) {
        index = next_index;
        const byte: u8 = str[index];
        const char_bytes_length = unicode.utf8ByteSequenceLength(byte) catch 0;
        next_index = next_index + char_bytes_length;
        // if (char_bytes_length < 2) continue;
        print("'{s}'", .{str[index..next_index]});
        var i: usize = 0;
        while (i < char_bytes_length) {
            print(":{b}", .{str[index + i]});
            i += 1;
        }
        print(" \n", .{});
    }
}
