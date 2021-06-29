// https://github.com/telexyz/telex-engine/blob/04f65c74ec3a0f0b8350fc518faddcf325665de4/src/tokenizer.zig

const std = @import("std");
const print = std.debug.print;

const Text = @import("./text_data_struct.zig").Text;
const text_utils = @import("./text_utils.zig");

inline fn printToken(token: []const u8, token_attrs: Text.TokenAttributes) void {
    if (token[0] == '\n') {
        print("\nNEWLINE: ", .{});
    } else {
        print("\"{s}\" => {}, {}\n", .{
            token,
            token_attrs.category,
            token_attrs.surrounded_by_spaces,
        });
    }
}

pub const Tokenizer = struct {
    max_lines_count: usize = 0,

    const CharTypes = enum {
        alphabet_char, // a..zA..Z
        marktone_char, // https://vi.wikipedia.org/wiki/Dấu_phụ
        nonalpha_char, // 30%-100%. 91 30% 100%. 30-100% 91. 2017 21/6, 1.148 1&
        space, // ' ' '\t' '\n'
    };

    pub fn segment(self: *Tokenizer, text: *Text) !void {
        var index: usize = undefined;
        var next_index: usize = 0;

        // Any text can be defined as a sequence of nonspace_token|space_token|...
        // A nonspace_token can be an alphabet_token or a nonalpha_token or
        // is composed of alphabet|nonalpha|... alternatively
        // Later we will break alphabet_token into:
        // * syllable
        // * marktone
        // And remaining is alphabet (a-zA-Z)

        var nonspace_token_start_at: usize = 0;
        var alphabet_token_start_at: usize = 0;
        var nonalpha_token_start_at: usize = 0;

        var in_nonspace_token_zone = true;
        var in_alphabet_token_zone = true;
        var contains_marktone_char = false;

        var first_byte: u8 = 0; // first byte of the utf-8 char
        var second_byte: u8 = 0; // second byte of the utf-8 char (if needed)
        var char_bytes_len: u3 = undefined; // an utf8 char may composed of 2,3,4 bytes
        var char_type: CharTypes = undefined;

        const input_bytes = text.input_bytes;
        const bytes_len = input_bytes.len;

        const five_percent = bytes_len / 20;
        var percentage: u8 = 0;
        var percentage_threshold = five_percent;

        var lines_count: usize = 0;
        const counting_lines: bool = self.max_lines_count > 0;

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
                // 'a'...'z', 'A'...'Z', '0'...'9' => {
                'a'...'z', 'A'...'Z' => {
                    char_type = .alphabet_char;
                },

                // The we normalize SPACE delimiters by converting tab to space
                // and treat newline \n as a hint to do smt special like:
                // counting progress percentage ... it will not work if the copus
                // don't use \n but it's seem to be a rare case.
                ' ' => {
                    char_type = .space;
                },
                '\t' => {
                    char_type = .space;
                    // Convert tab to space
                    first_byte = ' ';
                },
                '\n' => { // New line should be treated differently
                    // It's could be a hint for sentences / phrases break ...
                    char_type = .space;
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

                        const token_attrs: Text.TokenAttributes = .{ .category = if (contains_marktone_char) .marktone else .alphabet, .surrounded_by_spaces = if (alphabet_token_start_at > nonspace_token_start_at) .right else .both };

                        try text.countToken(token, token_attrs);
                        if (counting_lines) printToken(token, token_attrs);
                        //
                    } else {
                        //
                        const token = input_bytes[nonalpha_token_start_at..index];

                        const token_attrs: Text.TokenAttributes = .{
                            .category = .nonalpha,
                            .surrounded_by_spaces = if (nonalpha_token_start_at > nonspace_token_start_at) .right else .both,
                        };

                        try text.countToken(token, token_attrs);
                        if (counting_lines) printToken(token, token_attrs);
                        //
                    }
                } // END if (in_nonspace_token_zone)
                //
                if (first_byte == '\n') {
                    // Record newline to treat special token
                    // it's category is nonalpha but we can check it value
                    // to know it's newline token
                    const token = input_bytes[index .. index + 1];
                    const token_attrs = Text.TokenAttributes{
                        .category = .nonalpha,
                        .surrounded_by_spaces = .none,
                    };
                    try text.countToken(token, token_attrs);

                    if (counting_lines) {
                        printToken(token, token_attrs);
                        lines_count += 1;
                        print("{d}\n\n", .{lines_count});
                        if (counting_lines and lines_count >= self.max_lines_count) {
                            return;
                        }
                    }

                    if (index > percentage_threshold) {
                        percentage += 5;
                        print("Segmenting {d}%\n", .{percentage});
                        percentage_threshold += five_percent;
                    }
                }
                // END char_type => .space
            } else {
                // char_type => .alphabet_char, or .nonalpha_char
                if (char_type == .nonalpha_char) {
                    if (!in_nonspace_token_zone) {
                        in_nonspace_token_zone = true;
                        nonspace_token_start_at = index;
                        nonalpha_token_start_at = index;
                        alphabet_token_start_at = next_index;
                        contains_marktone_char = false;
                    }

                    if (in_alphabet_token_zone) {
                        in_alphabet_token_zone = false;
                        // Record alphabets
                        if (alphabet_token_start_at <= index) {
                            const token = input_bytes[alphabet_token_start_at..index];
                            const token_attrs: Text.TokenAttributes = .{
                                .category = if (contains_marktone_char) .marktone else .alphabet,
                                .surrounded_by_spaces = if (alphabet_token_start_at == nonspace_token_start_at) .left else .none,
                            };

                            try text.countToken(token, token_attrs);
                            if (counting_lines) printToken(token, token_attrs);
                            //
                            contains_marktone_char = false;
                        }
                    }

                    alphabet_token_start_at = next_index;
                    //
                } else {
                    // char_type => .alphabet_char, .marktone_char
                    if (!in_nonspace_token_zone) {
                        in_nonspace_token_zone = true;
                        nonspace_token_start_at = index;
                        alphabet_token_start_at = index;
                        nonalpha_token_start_at = next_index;
                        contains_marktone_char = false;
                    }

                    if (char_type == .marktone_char)
                        contains_marktone_char = true;

                    if (!in_alphabet_token_zone) {
                        in_alphabet_token_zone = true;
                        // Record nonalpha
                        if (nonalpha_token_start_at <= index) {
                            const token = input_bytes[nonalpha_token_start_at..index];
                            const token_attrs: Text.TokenAttributes = .{
                                .category = .nonalpha,
                                .surrounded_by_spaces = if (nonalpha_token_start_at == nonspace_token_start_at) .left else .none,
                            };

                            try text.countToken(token, token_attrs);
                            if (counting_lines) printToken(token, token_attrs);
                            //
                            contains_marktone_char = false;
                        }
                    }

                    nonalpha_token_start_at = next_index;
                }
            }
        } // End main loop
    }
};

test "Tokenizer" {
    var text: Text = .{ .init_allocator = std.testing.allocator };
    try text.initFromFile("_input/corpus/test.txt");
    defer text.deinit();

    var tknz: Tokenizer = .{
        .max_lines_count = 100, // For testing process maximum 100 lines only
    };

    try tknz.segment(&text);

    text.tokens_number_finalized = true;
    text_utils.telexifyAlphabetTokens(&text);
}
