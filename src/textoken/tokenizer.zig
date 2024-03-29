// This is re-written of the original lengthy version
// https://github.com/telexyz/engine/blob/04f65c74ec3a0f0b8350fc518faddcf325665de4/src/tokenizer.zig

const std = @import("std");
const print = std.debug.print;

const Text = @import("./text_data_struct.zig").Text;
const text_utils = @import("./text_utils.zig");

inline fn printToken(token: []const u8, attrs: Text.TokenAttributes) void {
    if (token[0] == '\n') {
        print("\nNEWLINE: ", .{});
    } else {
        print("\"{s}\" => {}, {}\n", .{
            token,
            attrs.category,
            attrs.fenced_by_spaces,
        });
    }
}

pub const Tokenizer = struct {
    max_lines: usize = 0,

    const CharTypes = enum {
        alphabet_char, // a..zA..Z
        marktone_char, // https://vi.wikipedia.org/wiki/Dấu_phụ
        nonalpha_char, // 30%-100%. 91 30% 100%. 30-100% 91. 2017 21/6, 1.148 1&
        space, // ' ' '\t' '\n'
    };

    pub fn segment(self: *Tokenizer, text: *Text, then_parse_syllable: bool) !void {
        // @setRuntimeSafety(false); // !!! DANGER: PLAY WITH FIRE !!!
        const message = if (then_parse_syllable) "Segmenting & Parsing" else "Segmenting";

        var index: usize = undefined;
        var next_index: usize = 0;

        // Any text can be defined as a sequence of nonspace_token|space_token|...
        // A nonspace_token can be an alphabet_token or a nonalpha_token or
        // is composed of alphabet|nonalpha|... alternatively
        // Later we will break alphabet_token into:
        // * syllable
        // * alphmark
        // And remaining is alphabet (a-zA-Z)

        var nonspace_token_start_at: usize = 0;
        var alphabet_token_start_at: usize = 0;
        var nonalpha_token_start_at: usize = 0;

        var in_nonspace_token_zone = true;

        // Mặc định token đầu tiên là nonalpha, nếu ko phải sẽ ghi nhận token rỗng
        // token.len = 0, sẽ cần escape trường trong Text.recordToken
        var in_alphabet_token_zone = false;
        var contains_marktone_char = false;

        var first_byte: u8 = 0; // first byte of the utf-8 char
        var second_byte: u8 = 0; // second byte of the utf-8 char (if needed)
        var char_bytes_len: u3 = undefined; // an utf8 char may composed of 2,3,4 bytes
        var char_type: CharTypes = undefined;

        const input_bytes = text.input_bytes;
        const bytes_len = input_bytes.len;

        const ten_percents = bytes_len / 10;
        var percents: u8 = 0;
        var percents_threshold = ten_percents;

        var lines_count: usize = 0;
        const counting_lines: bool = self.max_lines > 0;

        // Main loop to iterate the whole input stream, utf-8 char by utf-8 char
        while (next_index < bytes_len) {
            // Get the first (valid) byte of the next utf-8 char from input stream
            index = next_index;
            first_byte = input_bytes[index];

            // char_bytes_len can be 1,2,3,4 depend on which
            // what is the next utf-8 char in the input stream
            // We process ascii char (first_byte < 128) first
            // so we init char_bytes_len value to 1
            char_bytes_len = 1;

            // The main purpose of the switch filter here is to split input utf-8 char
            // stream into tokens and SPACE delimiters - the MOST FUNDAMENTAL segmentation:
            // SPACE vs NON-SPACE so we ensure that no-information is missed!

            switch (first_byte) {
                // a-z, A-Z are very common so the chance we meet them is quite often
                // we filter them out first to speed up the filtering process
                'a'...'z', 'A'...'Z' => {
                    char_type = .alphabet_char;
                },

                // Normalize SPACE delimiters by converting tab to space and treat
                // newline \n as a hint to do something special like: counting
                // progress percents ... it will not work if the copus
                // don't use \n but it's seem to be a rare case.
                32 => {
                    char_type = .space;
                },
                '\n' => {
                    // New line should be treated differently
                    // It's could be a hint for sentences / phrases break ...
                    char_type = .space;
                },
                '\t' => {
                    char_type = .space;
                    first_byte = ' '; // Convert to space
                },
                '\\' => {
                    // \r = CR (Carriage Return)
                    //      → Used as a new line character in Mac OS before X
                    // \n = LF (Line Feed)
                    //      → Used as a new line character in Unix/Mac OS X
                    // \r\n = CR + LF → Used as a new line character in Windows
                    switch (input_bytes[index + 1]) {
                        'n' => {
                            char_bytes_len = 2;
                            char_type = .space;
                            first_byte = 16; // Convert to special char
                        },
                        'r', 't' => {
                            // Handle "\n" in facebook comments
                            char_bytes_len = 2;
                            char_type = .space;
                            first_byte = ' '; // Convert to space
                        },
                        else => {
                            char_type = .nonalpha_char;
                        },
                    }
                },
                else => {
                    // Based on code of zig std lib
                    // pub fn utf8ByteSequenceLength(first_byte: u8) !u3 {
                    // 0b0000_0000...0b0111_1111 => 1,
                    // 0b1100_0000...0b1101_1111 => 2,
                    // 0b1110_0000...0b1110_1111 => 3,
                    // 0b1111_0000...0b1111_0111 => 4,
                    // else => error.Utf8InvalidStartByte,

                    // uninterested ascii and utf-8 chars, we marked them as .nonalpha_char
                    char_type = .nonalpha_char;

                    if (first_byte > 0b1111_0111) {
                        @panic("error.Utf8InvalidStartByte");
                    }

                    // The most important thing here is we determine char_bytes_len
                    // So later we increase next_index pointer to a VALID byte
                    if (first_byte <= 0b0111_1111) {
                        char_bytes_len = 1;
                    } else if (0b1100_0000 <= first_byte and first_byte <= 0b1101_1111) {
                        char_bytes_len = 2;
                        second_byte = input_bytes[index + 1];

                        //   or &nbsp;
                        if (first_byte == 194 and second_byte == 160) {
                            char_type = .space;
                            first_byte = ' '; // Convert to space
                        }

                        // Rough filter to see if it .marktone_char
                        if (195 <= first_byte and first_byte <= 198 and
                            128 <= second_byte and second_byte <= 189)
                        {
                            char_type = .marktone_char;
                        }
                        if ((first_byte == 204 or first_byte == 205) and
                            128 <= second_byte and second_byte <= 163)
                        {
                            char_type = .marktone_char;
                        }
                    } else if (first_byte == 225) {
                        char_bytes_len = 3;
                        second_byte = input_bytes[index + 1];
                        // Rough filter to see if it .marktone_char
                        if (second_byte == 186 or second_byte == 187) {
                            char_type = .marktone_char;
                        }
                    } else {
                        char_bytes_len = if (0b1111_0000 <= first_byte and
                            first_byte <= 0b1111_0111) 4 else 3;
                    }
                },
            }

            // Point the next_index pointer to the next VALID byte
            next_index = index + char_bytes_len;

            if (char_type == .space) {
                // in_nonspace_token_zone bool variable let us know that if the
                // current char is belongs to a token or is SPACE delimitor
                if (in_nonspace_token_zone) {
                    // Current char is SPACE delimitor
                    // so we are not in token zone anymore
                    in_nonspace_token_zone = false;

                    if (in_alphabet_token_zone) {
                        //
                        const token = input_bytes[alphabet_token_start_at..index];
                        const attrs: Text.TokenAttributes = .{ .category = if (contains_marktone_char) .alphmark else .alph0m0t, .fenced_by_spaces = if (alphabet_token_start_at > nonspace_token_start_at) .right else .both };
                        try text.recordToken(token, attrs, then_parse_syllable);
                        if (counting_lines) printToken(token, attrs);
                        //
                    } else {
                        //
                        const token = input_bytes[nonalpha_token_start_at..index];
                        const attrs: Text.TokenAttributes = .{
                            .category = .nonalpha,
                            .fenced_by_spaces = if (nonalpha_token_start_at > nonspace_token_start_at) .right else .both,
                        };
                        try text.recordToken(token, attrs, then_parse_syllable);
                        if (counting_lines) printToken(token, attrs);
                        //
                    }
                } // END if (in_nonspace_token_zone)
                //
                if (first_byte == '\n' or first_byte == 16) {
                    // Record newline to treat special token
                    // it's category is nonalpha but we can check it value
                    // to know if it's newline token later
                    var extra: u8 = 1; if (first_byte == 16) extra = 2;
                    const token = input_bytes[index .. index + extra];
                    const attrs = Text.TokenAttributes{
                        .category = .nonalpha,
                        .fenced_by_spaces = .both,
                    };
                    try text.recordToken(token, attrs, then_parse_syllable);
                    //
                    if (counting_lines) {
                        printToken(token, attrs);
                        lines_count += 1;
                        print("{d}\n\n", .{lines_count});
                        if (counting_lines and lines_count >= self.max_lines) return;
                    }
                    // Show progress ...
                    if (index > percents_threshold) {
                        percents += 10;
                        print("{s} {d}%\n", .{ message, percents });
                        percents_threshold += ten_percents;
                    }
                }
                // END char_type => .space

            } else { // char_type => .alphabet_char, or .nonalpha_char

                // This checkin only happen once at the start of nonspace token
                if (!in_nonspace_token_zone) {
                    //
                    in_nonspace_token_zone = true;
                    nonspace_token_start_at = index;

                    if (char_type == .nonalpha_char) {
                        //
                        in_alphabet_token_zone = false;
                        alphabet_token_start_at = next_index;
                        nonalpha_token_start_at = index;
                        //
                    } else {
                        //
                        in_alphabet_token_zone = true;
                        contains_marktone_char = (char_type == .marktone_char);
                        alphabet_token_start_at = index;
                        nonalpha_token_start_at = next_index;
                    }
                    // next char please
                    continue;
                }

                // For other chars of nonespace token, check to split into
                // nonalpha tokens and alphabet tokens
                if (char_type == .nonalpha_char) {
                    if (in_alphabet_token_zone) {
                        // Record alphabet
                        const token = input_bytes[alphabet_token_start_at..index];
                        const attrs: Text.TokenAttributes = .{
                            .category = if (contains_marktone_char) .alphmark else .alph0m0t,
                            .fenced_by_spaces = if (alphabet_token_start_at == nonspace_token_start_at) .left else .none,
                        };
                        try text.recordToken(token, attrs, then_parse_syllable);
                        if (counting_lines) printToken(token, attrs);
                        // Reset for nonalpha
                        in_alphabet_token_zone = false;
                    }
                    alphabet_token_start_at = next_index;
                    //
                } else {
                    // char_type => .alphabet_char, .marktone_char
                    if (!in_alphabet_token_zone) {
                        // Record nonalpha
                        const token = input_bytes[nonalpha_token_start_at..index];
                        const attrs: Text.TokenAttributes = .{
                            .category = .nonalpha,
                            .fenced_by_spaces = if (nonalpha_token_start_at == nonspace_token_start_at) .left else .none,
                        };
                        try text.recordToken(token, attrs, then_parse_syllable);
                        if (counting_lines) printToken(token, attrs);
                        // Reset for alphabet
                        in_alphabet_token_zone = true;
                        contains_marktone_char = (char_type == .marktone_char);
                    }
                    if (char_type == .marktone_char) contains_marktone_char = true;
                    nonalpha_token_start_at = next_index;
                }
            } // End else char_type => .alphabet_char, or .nonalpha_char
        } // End main loop
        // Notify text that there is no more token
        text.tokens_num_finalized = true;
    }
};

const testing = std.testing;

test "Tokenizer" {
    const input_bytes =
        \\Giá       trúng    binh quân 13.011 đồng/cp, thu về hơn 1.300 voọc.
        \\HeirsNguyễn tránh TP.Long Xuyên sẽ 'khai tử' trạm BOT T2.
        \\https://vnexpress.net/cdc-tinh-dong-thap-dong-cua-4299620.html
        \\
    ;
    // var text: Text = .{ .init_allocator = std.testing.allocator };
    var text: Text = .{ .init_allocator = std.heap.page_allocator };
    try text.initFromInputBytes(input_bytes);
    defer text.deinit();

    var tknz: Tokenizer = .{
        // .max_lines = 100, // For testing process maximum 100 lines only
    };

    try tknz.segment(&text, false);

    const s1_tokens = "Giá trúng binh quân 13.011 đồng / cp , thu về hơn 1.300 voọc .";
    var s1_tkcats = &[15]Text.TokenCategory{ .alphmark, .alphmark, .alph0m0t, .alphmark, .nonalpha, .alphmark, .nonalpha, .alph0m0t, .nonalpha, .alph0m0t, .alphmark, .alphmark, .nonalpha, .alphmark, .nonalpha };
    const s1_surrds = &[15]Text.TokenFencedBySpaces{ .both, .both, .both, .both, .both, .left, .none, .none, .right, .both, .both, .both, .both, .left, .right };

    var it = std.mem.split(u8, s1_tokens, " ");
    var i: usize = 0;
    while (it.next()) |token| : (i += 1) {
        // print("Token: {s}\n", .{text.getToken(i)}); //DEBUG
        try testing.expectEqualStrings(token, text.getToken(i));
        try testing.expectEqual(s1_tkcats[i], text.tokens_infos.get(i).attrs.category);
        try testing.expectEqualStrings(@tagName(s1_surrds[i]), @tagName(text.tokens_infos.get(i).attrs.fenced_by_spaces));
    }

    try std.testing.expectEqualStrings("\n", text.getToken(i));
    const s2_tokens = "HeirsNguyễn tránh TP . Long Xuyên sẽ ' khai tử ' trạm BOT T 2.";
    var s2_tkcats = &[15]Text.TokenCategory{ .alphmark, .alphmark, .alph0m0t, .nonalpha, .alph0m0t, .alphmark, .alphmark, .nonalpha, .alph0m0t, .alphmark, .nonalpha, .alphmark, .alph0m0t, .alph0m0t, .nonalpha };
    const s2_surrds = &[15]Text.TokenFencedBySpaces{ .both, .both, .left, .none, .right, .both, .both, .left, .right, .left, .right, .both, .both, .left, .right };
    it = std.mem.split(u8, s2_tokens, " ");
    i += 1;
    var j: usize = 0;
    while (it.next()) |token| {
        // print("Token: {s}\n", .{token});
        try testing.expectEqualStrings(token, text.getToken(i));
        try testing.expectEqualStrings(@tagName(s2_tkcats[j]), @tagName(text.tokens_infos.get(i).attrs.category));
        try testing.expectEqualStrings(@tagName(s2_surrds[j]), @tagName(text.tokens_infos.get(i).attrs.fenced_by_spaces));
        i += 1;
        j += 1;
    }

    try std.testing.expectEqualStrings("\n", text.getToken(i));
    const s3_tokens = "https :// vnexpress . net / cdc - tinh - dong - thap - dong - cua -4299620. html";
    it = std.mem.split(u8, s3_tokens, " ");
    i += 1;
    j = 0;
    while (it.next()) |token| {
        try testing.expectEqualStrings(token, text.getToken(i));
        const fenced_by_spaces = text.tokens_infos.get(i).attrs.fenced_by_spaces;
        switch (j) {
            0 => try testing.expect(fenced_by_spaces == .left),
            18 => try testing.expect(fenced_by_spaces == .right),
            else => try testing.expect(fenced_by_spaces == .none),
        }

        const category = text.tokens_infos.get(i).attrs.category;
        if (@rem(j, 2) == 0) {
            try testing.expect(category == .alph0m0t);
        } else {
            try testing.expect(category == .nonalpha);
        }
        i += 1;
        j += 1;
    }

    // Second passes, parseTokens
    try testing.expect(text.parsed_tokens_num == 0);
    // print("\ntokens_num: {}\n", .{text.tokens_num});
    try testing.expect(text.tokens_num == 15 + 15 + 19 + 3); // 3 * \n

    try testing.expect(text.tokens_num_finalized == true);
    text_utils.parseTokens(&text);
    try testing.expect(text.parsed_tokens_num == text.tokens_num);

    const s1_parsed_tokens = "^gia|s trung|s binh| quan|z 13.011 ddong|zf / cp , thu| ve|zf hon|w 1.300 vooc|j .";
    s1_tkcats = &[15]Text.TokenCategory{ .syllmark, .syllmark, .syll0m0t, .syllmark, .nonalpha, .syllmark, .nonalpha, .alph0m0t, .nonalpha, .syll0m0t, .syllmark, .syllmark, .nonalpha, .syllmark, .nonalpha };
    it = std.mem.split(u8, s1_parsed_tokens, " ");
    i = 0;
    while (it.next()) |token| {
        // print("\nToken: {s}, {s}", .{ token, text.getToken(i) }); //DEBUG
        try testing.expectEqualStrings(token, text.getToken(i));
        try testing.expectEqualStrings(@tagName(s1_tkcats[i]), @tagName(text.tokens_infos.get(i).attrs.category));
        i += 1;
    }

    try std.testing.expectEqualStrings("\n", text.getToken(i));

    const s2_parsed_tokens = "HeirsNguyễn tranh|s TP . ^long| ^xuyen|z se|x ' khai| tu|wr ' tram|j BOT T 2.";
    s2_tkcats = &[15]Text.TokenCategory{ .alphmark, .syllmark, .alph0m0t, .nonalpha, .syll0m0t, .syllmark, .syllmark, .nonalpha, .syll0m0t, .syllmark, .nonalpha, .syllmark, .alph0m0t, .alph0m0t, .nonalpha };
    it = std.mem.split(u8, s2_parsed_tokens, " ");
    i += 1;
    j = 0;
    while (it.next()) |token| {
        try testing.expectEqualStrings(token, text.getToken(i));
        // print("Token: {s}\n", .{token}); //DEBUG
        try testing.expectEqualStrings(@tagName(s2_tkcats[j]), @tagName(text.tokens_infos.get(i).attrs.category));
        // try testing.expect(s2_tkcats[j] == text.tokens_infos.get(i).attrs.category);
        i += 1;
        j += 1;
    }
}
