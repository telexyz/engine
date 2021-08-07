const std = @import("std");
const print = std.debug.print;
const unicode = std.unicode;

// https://www.windmill.co.uk/ascii-control-codes.html
// Avoid: 0 null, 8 backspace, \x09 (\t-9-tab), \x0a (\n-10-newline),\x0d (13-enter)
// Dùng được 27 invisible ascii chars, 1-8, 11,12, 15-31
// var str = "|\x01\x02\x03\x04\x05\x06\x07\x08\x0b\x0c\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f|";

// var str = "\n\tđĐàáãâăèéêìíĩòóõôơýùúũưủụọỏịỉỳỵỷỹạảẹẻẽẦẤẬẨẪẰẮẶẲẴỀẾỆỂỄỒỐỘỔỖỜỚỢỞỠỪỨỰỬỮầấậẩẫằắặẳẵềếệểễồốộổỗờớợởỡừứựửữ";
// var str = "×÷ ̣ ̂́ ̉ ̂ ̛̣ ̂̃ ̣̂ ̂̉ ̛ ̛̀ ̃ ̛́ ̛̉ ̆̀ ͡ ̆́ıąö ͙͕ ";
// var str = "ộðÐiề";

var str = "🤷🏻‍♀️";

// var str = "▁ÀÁÂÁẦẤẪẨẦẤẰẮẴẲẰẮẬẶẢǍẠẬÀÁÈÉÊà";
// var str = "qrtpdghklxcvbnm";
// var str = "weyuio";

// var str = "qsdklxvb"; // chỉ có thể đứng ở đầu âm tiết
// var str = "wfjz"; // Ko có trong âm tiết utf8
// var str = "cmnpthg"; // Đứng cuối ko là nguyên âm chỉ có thể là

// var str = "qwertyuiopasdfghjklzxcvbnm";

// 2-bytes-utf8 chars | look exactly like ascii
// var str = "АВМСКоНРрЕ|ABMCKoHPpE";

pub fn main() !void {
    var file = try std.fs.cwd().createFile("data/play_with_chars.txt", .{});
    defer file.close();
    _ = try file.writer().write(str);

    print("\n{s}\n", .{str});

    var index: usize = undefined;
    var next_index: usize = 0;

    print("\nlen: {d}\n\n", .{str.len});
    next_index = 0;
    while (next_index < str.len) {
        index = next_index;
        const byte: u8 = str[index];
        const char_bytes_length = try unicode.utf8ByteSequenceLength(byte);
        next_index = next_index + char_bytes_length;
        // if (byte & 0b1100010 != 0b1100010) continue;
        const char = try unicode.utf8Decode(str[index..next_index]);
        print("'{s}' => {d}", .{ str[index..next_index], char });
        var i: usize = 0;
        while (i < char_bytes_length) {
            const b = str[index + i];
            print(" : byte-{d} {x} {d}", .{ i, b, b });
            i += 1;
        }
        print(" \n", .{});
    }

    // while (next_index < str.len) {
    //     index = next_index;
    //     const byte: u8 = str[index];
    //     const char_bytes_length = unicode.utf8ByteSequenceLength(byte) catch 0;
    //     next_index = next_index + char_bytes_length;
    //     print("{d}", .{char_bytes_length});
    // }

    // print("\n\n", .{});
    // next_index = 0;
    // while (next_index < str.len) {
    //     index = next_index;
    //     const byte: u8 = str[index];
    //     const char_bytes_length = unicode.utf8ByteSequenceLength(byte) catch 0;
    //     next_index = next_index + char_bytes_length;
    //     if (char_bytes_length < 2) continue;
    //     const char = unicode.utf8Decode(str[index..next_index]);
    //     print(" '{s}'{d}", .{ str[index..next_index], char });
    // }

}
