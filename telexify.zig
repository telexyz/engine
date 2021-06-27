const std = @import("std");
const print = std.debug.print;
const time = std.time;
const unicode = std.unicode;
const File = std.fs.File;

const parsers = @import("./src/parsers.zig");
const telex_utils = @import("./src/telex_utils.zig");
const chars_utils = @import("./src/chars_utils.zig");
const U2ACharStream = chars_utils.Utf8ToAsciiTelexAmTietCharStream;
const Text = @import("./src/text.zig").Text;

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

const TextFileTokenizer = struct {
    max_lines_count: usize = 0,

    init_allocator: *std.mem.Allocator,
    arena: std.heap.ArenaAllocator = undefined,
    allocator: *std.mem.Allocator = undefined,

    input_file: File = undefined,
    input_bytes: []const u8 = undefined,

    // Mixed of alphabet and non-alphabet (or not-pure) tokens,
    // splitted by space delimiter
    mixed_tokens_map: std.StringHashMap(void) = undefined,

    text: Text = undefined,

    const MAX_INPUT_FILE_SIZE = 600 * 1024 * 1024; // 600mb

    pub fn init(self: *TextFileTokenizer, input_filename: []const u8) !void {
        self.arena = std.heap.ArenaAllocator.init(self.init_allocator);
        self.allocator = &self.arena.allocator;

        self.input_file = try std.fs.cwd().openFile(input_filename, .{ .read = true });
        self.input_bytes = try self.input_file.reader().readAllAlloc(self.allocator, MAX_INPUT_FILE_SIZE);

        self.text = Text{
            .init_allocator = self.init_allocator,
            .input_bytes = self.input_bytes,
        };
        try self.text.init();

        self.mixed_tokens_map = std.StringHashMap(void).init(self.allocator);
    }

    pub fn deinit(self: *TextFileTokenizer) void {
        self.input_file.close();
        self.text.deinit();
        self.arena.deinit();
    }

    const CharTypes = enum {
        alphabet_char,
        marktone_char, // https://vi.wikipedia.org/wiki/Dấu_phụ
        nonalpha_char,
        space,
    };

    pub fn segment(self: *TextFileTokenizer) !void {
        var index: usize = undefined;
        var next_index: usize = 0;

        // Any text can be defined as a sequence of nonspace_token|space_token|...
        // A nonspace_token can be a alphabet_token or a nonalpha or
        // is composed of alphabet|nonalpha|... alternatively

        var nonspace_token_start_at: usize = 0;
        var alphabet_token_start_at: usize = 0;
        var nonalpha_token_start_at: usize = 0;

        var in_nonspace_token_zone = true;
        var in_alphabet_token_zone = true;
        // A spacious_{alphabet|nonalpha} is a whole nonspace_token
        var is_spacious_alphabet = true;
        var is_spacious_nonalpha = true;
        var contains_marktone_char = false;

        var first_byte: u8 = 0; // first byte of the utf-8 char
        var byte2: u8 = 0; // second byte of the utf-8 char (if needed)
        var char_bytes_length: u3 = undefined;
        var char_type: CharTypes = undefined;

        const input_bytes = self.input_bytes;
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

            // char_bytes_length can be 1,2,3,4 depend on which
            // what is the next utf-8 char in the input stream
            // We process ascii char (first_byte < 128) first
            // so we init char_bytes_length value to 1
            char_bytes_length = 1;

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

                    // The most important thing here is we determine char_bytes_length
                    // So later we increase next_index pointer to a VALID byte
                    if (first_byte <= 0b0111_1111) {
                        char_bytes_length = 1;
                    } else if (0b1100_0000 <= first_byte and first_byte <= 0b1101_1111) {
                        char_bytes_length = 2;
                        byte2 = input_bytes[index + 1];
                        // Rough filter to see if it .marktone_char
                        if (195 <= first_byte and first_byte <= 198 and
                            128 <= byte2 and byte2 <= 189)
                            char_type = .marktone_char;

                        if ((first_byte == 204 or first_byte == 205) and
                            128 <= byte2 and byte2 <= 163)
                            char_type = .marktone_char;
                        //
                    } else if (first_byte == 225) {
                        char_bytes_length = 3;
                        byte2 = input_bytes[index + 1];
                        // Rough filter to see if it .marktone_char
                        if (byte2 == 186 or byte2 == 187)
                            char_type = .marktone_char;
                        //
                    } else if (0b1111_0000 <= first_byte and first_byte <= 0b1111_0111) {
                        char_bytes_length = 4;
                    } else {
                        char_bytes_length = 3;
                    }
                },
            }
            // Point the next_index pointer to the next VALID byte
            next_index = index + char_bytes_length;

            if (char_type == .space) {
                // in_nonspace_token_zone bool variable let us know that if the
                // current char is belongs to a token or is SPACE delimitor
                if (in_nonspace_token_zone) {
                    // Current char is SPACE delimitor
                    // so we are not in token zone anymore
                    in_nonspace_token_zone = false;

                    // This is the first time we get out of token_zone
                    // so we end the current token at current byte index
                    if (is_spacious_alphabet) {
                        //
                        const token = input_bytes[nonspace_token_start_at..index];

                        const token_attrs: Text.TokenAttributes = .{
                            .category = if (contains_marktone_char) .marktone else .alphabet,
                            .surrounded_by_spaces = .both,
                        };

                        try self.text.countToken(token, token_attrs);
                        if (counting_lines) printToken(token, token_attrs);
                        //
                    } else {
                        //
                        const token = input_bytes[nonspace_token_start_at..index];

                        if (is_spacious_nonalpha) {
                            //
                            const token_attrs: Text.TokenAttributes = .{
                                .category = .nonalpha,
                                .surrounded_by_spaces = .both,
                            };

                            try self.text.countToken(token, token_attrs);
                            if (counting_lines) printToken(token, token_attrs);
                            //
                        } else {
                            _ = try self.mixed_tokens_map.getOrPut(token);
                        }
                    }

                    if (in_alphabet_token_zone and alphabet_token_start_at > nonspace_token_start_at) {
                        //
                        const token = input_bytes[alphabet_token_start_at..index];

                        const token_attrs: Text.TokenAttributes = .{
                            .category = if (contains_marktone_char) .marktone else .alphabet,
                            .surrounded_by_spaces = .right,
                        };

                        try self.text.countToken(token, token_attrs);
                        if (counting_lines) printToken(token, token_attrs);
                        //
                    }

                    if (!in_alphabet_token_zone and nonalpha_token_start_at > nonspace_token_start_at) {
                        //
                        const token = input_bytes[nonalpha_token_start_at..index];

                        const token_attrs: Text.TokenAttributes = .{
                            .category = .nonalpha,
                            .surrounded_by_spaces = .right,
                        };

                        try self.text.countToken(token, token_attrs);
                        if (counting_lines) printToken(token, token_attrs);
                        //
                    }
                } // END if (in_nonspace_token_zone)
                if (first_byte == '\n') {
                    // Record newline to treat special token
                    // it's category is nonalpha but we can check it value
                    // to know it's newline token
                    const token = input_bytes[index .. index + 1];
                    const token_attrs = Text.TokenAttributes{
                        .category = .nonalpha,
                        .surrounded_by_spaces = .none,
                    };
                    try self.text.countToken(token, token_attrs);

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
            } else { // char_type => .alphabet_char, or .nonalpha_char
                if (char_type == .nonalpha_char) {
                    if (!in_nonspace_token_zone) {
                        in_nonspace_token_zone = true;
                        // Reset indexes
                        nonspace_token_start_at = index;
                        alphabet_token_start_at = next_index;
                        nonalpha_token_start_at = index;
                        // Reset flags
                        is_spacious_alphabet = true;
                        is_spacious_nonalpha = true;
                        contains_marktone_char = false;
                    }

                    is_spacious_alphabet = false;

                    if (in_alphabet_token_zone) {
                        in_alphabet_token_zone = false;
                        // Record alphabets
                        if (alphabet_token_start_at <= index) {
                            //
                            const token = input_bytes[alphabet_token_start_at..index];
                            const first = alphabet_token_start_at == nonspace_token_start_at;

                            const token_attrs: Text.TokenAttributes = .{
                                .category = if (contains_marktone_char) .marktone else .alphabet,
                                .surrounded_by_spaces = if (first) .left else .none,
                            };

                            try self.text.countToken(token, token_attrs);
                            if (counting_lines) printToken(token, token_attrs);
                            //
                            contains_marktone_char = false;
                        }
                    }
                    alphabet_token_start_at = next_index;
                } else { // char_type => .alphabet_char, .marktone_char
                    if (!in_nonspace_token_zone) {
                        in_nonspace_token_zone = true;
                        // Reset indexes
                        nonspace_token_start_at = index;
                        alphabet_token_start_at = index;
                        nonalpha_token_start_at = next_index;
                        // Reset flags
                        is_spacious_alphabet = true;
                        is_spacious_nonalpha = true;
                        contains_marktone_char = false;
                    }

                    if (char_type == .marktone_char)
                        contains_marktone_char = true;

                    is_spacious_nonalpha = false;

                    if (!in_alphabet_token_zone) {
                        in_alphabet_token_zone = true;
                        // Record nonalpha
                        if (nonalpha_token_start_at <= index) {
                            //
                            const token = input_bytes[nonalpha_token_start_at..index];
                            const first = nonalpha_token_start_at == nonspace_token_start_at;

                            const token_attrs: Text.TokenAttributes = .{
                                .category = .nonalpha,
                                .surrounded_by_spaces = if (first) .left else .none,
                            };

                            try self.text.countToken(token, token_attrs);
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

    fn write_mixed_tokens_to_file(self: *TextFileTokenizer, output_filename: []const u8) !void {
        var file = try std.fs.cwd().createFile(output_filename, .{});
        defer file.close();
        var tokens_count: usize = 0;
        var it = self.mixed_tokens_map.iterator();
        while (it.next()) |kv| {
            const token = kv.key_ptr.*;

            _ = try file.writer().write(token);
            tokens_count += 1;

            if (@rem(tokens_count, 12) == 0)
                _ = try file.writer().write("\n")
            else
                _ = try file.writer().write("   ");
        }
    }

    fn write_output_file_from_tokens(
        self: TextFileTokenizer,
        output_filename: []const u8,
        max: usize,
    ) !void {
        var n = self.text.tokens_number;
        if (max > 0 and n > max) n = max;
        // Open files to write transformed input data (final result)
        var output_file = try std.fs.cwd().createFile(output_filename, .{});
        defer output_file.close();

        var i: usize = 0;

        while (i < n) : (i += 1) {
            const attrs = self.text.tokens_attrs[i];
            var token = self.text.tokens[i];

            if (attrs.category == .syllable) {
                token = self.text.transforms[i];
            }
            _ = try output_file.writer().write(token);

            if (attrs.surrounded_by_spaces == .both or
                attrs.surrounded_by_spaces == .right)
                _ = try output_file.writer().write(" ");
        }
    }

    fn write_output_file_from_buffer(
        self: TextFileTokenizer,
        output_filename: []const u8,
        max: usize,
    ) !void {
        var n = self.text.transformed_bytes_len;
        if (max > 0 and n > max) n = max;
        // Open files to write transformed input data (final result)
        var output_file = try std.fs.cwd().createFile(output_filename, .{});
        defer output_file.close();
        _ = try output_file.writer().write(self.text.transformed_bytes[0..n]);
    }

    fn write_alphabet_types_to_files(
        self: TextFileTokenizer,
        marktone_filename: []const u8,
        alphabet_filename: []const u8,
    ) !void {
        var alphabet_file = try std.fs.cwd().createFile(alphabet_filename, .{});
        var marktone_file = try std.fs.cwd().createFile(marktone_filename, .{});
        defer alphabet_file.close();
        defer marktone_file.close();

        const max_token_len = 30;
        var buffer: [max_token_len + 15]u8 = undefined;
        const buff_slice = buffer[0..];

        var it = self.text.alphabet_types.iterator();
        while (it.next()) |kv| {
            if (max_token_len < kv.key_ptr.*.len) {
                print("TOKEN TOO LONG: {s}\n", .{kv.key_ptr.*});
                continue;
            }
            const result = try std.fmt.bufPrint(buff_slice, "{d:10}  {s}\n", .{ kv.value_ptr.*.count, kv.key_ptr.* });
            if (kv.value_ptr.*.category == .marktone) {
                _ = try marktone_file.writer().write(result);
            } else {
                _ = try alphabet_file.writer().write(result);
            }
        }
    }
};

fn write_counts_to_file(counts: anytype, output_filename: []const u8) !void {
    var output_file = try std.fs.cwd().createFile(output_filename, .{});
    defer output_file.close();

    const max_token_len = 30;
    var buffer: [max_token_len + 15]u8 = undefined;
    const buff_slice = buffer[0..];

    var it = counts.iterator();
    while (it.next()) |kv| {
        if (max_token_len < kv.key_ptr.*.len) {
            print("TOKEN TOO LONG: {s}\n", .{kv.key_ptr.*});
            continue;
        }
        const count = if (comptime @TypeOf(counts) == std.StringHashMap(Text.TypeInfo)) kv.value_ptr.*.count else kv.value_ptr.*;

        const result = try std.fmt.bufPrint(buff_slice, "{d:10}  {s}\n", .{ count, kv.key_ptr.* });
        _ = try output_file.writer().write(result);
    }
}

// Init and config a new TextFileTokenizer
var tp: TextFileTokenizer = undefined;

pub fn main() anyerror!void {
    const start_time = time.milliTimestamp();
    print("\nstart_time {}\n", .{start_time});

    // Advance the iterator since we want to ignore the binary name.
    var args = std.process.args();
    _ = args.nextPosix();
    // Get input filename from args
    const input_filename = args.nextPosix() orelse {
        std.debug.warn("expected input_filename as first argument\n", .{});
        std.os.exit(1);
    };
    // Get output filename from args
    const output_filename = args.nextPosix() orelse {
        std.debug.warn("expected output_filename as second argument\n", .{});
        std.os.exit(1);
    };
    // Optional, get max_lines_count from args
    const max_lines_count: usize = if (args.nextPosix() != null) 1001 else 0;

    tp = .{
        .init_allocator = std.heap.page_allocator,
        .max_lines_count = max_lines_count,
    };

    try tp.init(input_filename);
    defer tp.deinit();

    const init_ms = time.milliTimestamp() - start_time;
    const init_mins = @intToFloat(f32, init_ms) / 60000;
    print("\nInit Done! Duration {} ms => {d:.2} mins\n\n", .{ init_ms, init_mins });

    const thread = try std.Thread.spawn(Text.telexifyAlphabetTokens, &tp.text);
    try tp.segment();

    const step1_ms = time.milliTimestamp() - start_time;
    const step1_mins = @intToFloat(f32, step1_ms) / 60000;

    print("\nStep-1: Token segmenting finish! Duration {} ms => {d:.2} mins\n\n", .{ step1_ms, step1_mins });

    // Write out stats
    try write_counts_to_file(
        tp.text.nonalpha_types,
        "_output/05-nonalpha_types.txt",
    );
    try tp.write_mixed_tokens_to_file(
        "_output/06-mixed_tokens.txt",
    );

    // Write sample of final output
    try tp.write_output_file_from_tokens(
        "_output/07-telexified-777.txt",
        777,
    );

    // Wait for sylabeling thread end
    thread.wait();
    // Then run one more time to finalize sylabeling process
    // since there may be some last tokens was skipped before thread end
    // because sylabeling too fast and timeout before new tokens come
    // It's a very rare-case happend when the sleep() call fail.
    tp.text.tokens_number_finalized = true;
    tp.text.telexifyAlphabetTokens();
    tp.text.removeSyllablesFromAlphabetTypes();

    const step2_ms = time.milliTimestamp() - start_time;
    const step2_mins = @intToFloat(f32, step2_ms) / 60000;
    print("\nStep-2:  Token syllabling finish! Duration {} ms => {d:.2} mins\n\n", .{ step2_ms, step2_mins });

    print("\nWriting final transformation to file ...\n", .{});

    try write_counts_to_file(
        tp.text.syllable_types,
        "_output/01-syllable_types.txt",
    );
    try write_counts_to_file(
        tp.text.syllower_types,
        "_output/02-syllower_types.txt",
    );
    try tp.write_alphabet_types_to_files(
        "_output/03-marktone_types.txt",
        "_output/04-alphabet_types.txt",
    );
    try tp.write_output_file_from_buffer(
        "_output/08-telexified-888.txt",
        888_888,
    );
    // Final result
    try tp.write_output_file_from_buffer(output_filename, 0);

    const end_time = time.milliTimestamp();
    print("\nend_time {}\n", .{end_time});
    const duration = end_time - start_time;
    const minutes = @intToFloat(f32, duration) / 60000;
    print("Duration {} ms => {d:.2} mins\n\n", .{ duration, minutes });
}

test "Telexify" {
    var tfp: TextFileTokenizer = .{
        .init_allocator = std.testing.allocator,
        .max_lines_count = 100, // For testing process maximum 100 lines only
    };
    try tfp.init("_input/corpus/corpus-title-sample.txt");
    defer tfp.deinit();
    try tfp.segment();
    tfp.text.tokens_number_finalized = true;
    tfp.text.telexifyAlphabetTokens();
}
