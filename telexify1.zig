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

fn print_nothing(comptime fmt_str: []const u8, args: anytype) void {}

const TextFileTokenizer = struct {
    max_lines_count: usize = 0,

    init_allocator: *std.mem.Allocator,
    arena: std.heap.ArenaAllocator = undefined,
    allocator: *std.mem.Allocator = undefined,

    input_file: File = undefined,
    input_bytes: []const u8 = undefined,

    syllables1_file: File = undefined,
    syllables2_file: File = undefined,
    oov1_file: File = undefined,
    oov2_file: File = undefined,

    text: Text = undefined,

    oov1_count: usize = 0,
    oov2_count: usize = 0,
    syllables1_count: usize = 0,
    syllables2_count: usize = 0,

    const MAX_INPUT_FILE_SIZE = 600 * 1024 * 1024; // 600mb
    const syllables1_filename = "./_output/syllables1.txt";
    const syllables2_filename = "./_output/syllables2.txt";
    const oov1_filename = "./_output/oov1.txt";
    const oov2_filename = "./_output/oov2.txt";

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

        // Open files to write intermediate results
        self.syllables1_file = try std.fs.cwd().createFile(syllables1_filename, .{});
        self.syllables2_file = try std.fs.cwd().createFile(syllables2_filename, .{});
        self.oov1_file = try std.fs.cwd().createFile(oov1_filename, .{});
        self.oov2_file = try std.fs.cwd().createFile(oov2_filename, .{});

        self.oov1_count = 0;
        self.oov2_count = 0;
        self.syllables1_count = 0;
        self.syllables2_count = 0;
    }

    pub fn deinit(self: *TextFileTokenizer) void {
        self.input_file.close();

        self.syllables1_file.close();
        self.syllables2_file.close();

        self.oov1_file.close();
        self.oov2_file.close();

        self.text.deinit();
        self.arena.deinit();
    }

    // Supplement functions
    inline fn recordOovToken(self: *TextFileTokenizer, has_mark_or_tone: bool, token: []const u8) !void {
        if (has_mark_or_tone) { // Write it to oov1.txt
            _ = try self.oov1_file.writer().write(token);
            self.oov1_count += 1;
            if (@rem(self.oov1_count, 10) == 0)
                _ = try self.oov1_file.writer().write("\n")
            else
                _ = try self.oov1_file.writer().write("  ");
        } else { // Write it oov2.txt
            _ = try self.oov2_file.writer().write(token);
            self.oov2_count += 1;
            if (@rem(self.oov2_count, 10) == 0)
                _ = try self.oov2_file.writer().write("\n")
            else
                _ = try self.oov2_file.writer().write("  ");
        }
    }

    inline fn recordSyllableToken(self: *TextFileTokenizer, is_pure_utf8: bool, token: []const u8) !void {
        if (is_pure_utf8) {
            _ = try self.syllables1_file.writer().write(token);
            self.syllables1_count += 1;
            if (@rem(self.syllables1_count, 12) == 0)
                _ = try self.syllables1_file.writer().write("\n")
            else
                _ = try self.syllables1_file.writer().write("  ");
        } else {
            _ = try self.syllables2_file.writer().write(token);
            self.syllables2_count += 1;
            if (@rem(self.syllables2_count, 12) == 0)
                _ = try self.syllables2_file.writer().write("\n")
            else
                _ = try self.syllables2_file.writer().write("  ");
        }
    }

    const CharTypes = enum { syllable_char, can_be_syllable_char, space, others };

    pub fn parse(self: *TextFileTokenizer) !void {
        @setRuntimeSafety(false);

        var char_stream = U2ACharStream.init();
        var syllable = parsers.Syllable.init();

        var index: usize = undefined;
        var next_index: usize = 0;
        var token_start_at: usize = 0;

        var got_error: ?chars_utils.CharStreamError = null;
        var in_token_zone = true;

        var first_byte: u8 = 0; // first byte of the utf-8 char
        var prev_first_byte: u8 = undefined;
        var char_bytes_length: u3 = undefined;
        var char_type: CharTypes = undefined;

        // Store result of very-fast utf-8 char filter to know if utf-8 char can be
        // processed by telex-syllable parser or not
        var telex_code: u10 = undefined;

        const input_bytes = self.input_bytes;
        const bytes_len = input_bytes.len;

        const one_percent = bytes_len / 100;
        var percentage: u8 = 0;
        var percentage_threshold = one_percent;

        var lines_count: usize = 0;
        const counting_lines: bool = self.max_lines_count > 0;

        // Main loop to iterate the whole input stream, utf-8 char by utf-8 char
        while (next_index < bytes_len) {
            // Get the first (valid) byte of the next utf-8 char from input stream
            index = next_index;
            prev_first_byte = first_byte;
            first_byte = input_bytes[index];

            // char_bytes_length can be 1,2,3,4 depend on which
            // what is the next utf-8 char in the input stream
            // We process ascii char (first_byte < 128) first
            // so we init char_bytes_length value to 1
            char_bytes_length = 1;

            // a-z, A-Z is VN syllable char for sure
            // is_upper is used to distinguish a-z vs A-Z
            // it's a shortcut to speedup VN syllable detecting algorithm
            var is_upper = false;

            // The main purpose of the switch filter here is to split input utf-8 char
            // stream into tokens and SPACE delimiters - the MOST FUNDAMENTAL segmentation:
            // SPACE vs NON-SPACE so we ensure that no-information is missed!

            switch (first_byte) {
                // a-z, A-Z are very common so the chance we meet them is quite often
                // we filter them out first to speed up the filtering process
                'a'...'z' => {
                    char_type = .syllable_char;
                },
                'A'...'Z' => {
                    is_upper = true;
                    // Convert first_byte to ascii lowercase so the VN syllable parser
                    // (understand a-z only) will treat 'a' and 'A' the same ...
                    first_byte |= 0b00100000; // toLower
                    char_type = .syllable_char;
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
                    // counting_lines to used to limit number of input data
                    // to run a trial on a large data set
                    if (index > percentage_threshold) {
                        percentage += 1;
                        print("processed: {d}%\n", .{percentage});
                        percentage_threshold += one_percent;
                    }
                    if (counting_lines) {
                        lines_count += 1;
                        print("line: {d}\n", .{lines_count});
                        if (lines_count >= self.max_lines_count) {
                            return;
                        }
                    }
                },
                else => {
                    // pub fn utf8ByteSequenceLength(first_byte: u8) !u3 {
                    // 0b0000_0000...0b0111_1111 => 1,
                    // 0b1100_0000...0b1101_1111 => 2,
                    // 0b1110_0000...0b1110_1111 => 3,
                    // 0b1111_0000...0b1111_0111 => 4,
                    // else => error.Utf8InvalidStartByte,

                    // uninterested ascii and utf-8 chars, we marked them as .others
                    char_type = .others;

                    if (got_error != null) {
                        var temp = try unicode.utf8ByteSequenceLength(first_byte);
                        char_bytes_length = temp;
                        //
                    } else {
                        //
                        if (first_byte > 0b1111_0111) {
                            @panic("error.Utf8InvalidStartByte");
                        }

                        var byte2 = input_bytes[index + 1];

                        // The most important thing here is we determine char_bytes_length
                        // So later we increase next_index pointer to a VALID byte
                        if (first_byte <= 0b0111_1111) {
                            char_bytes_length = 1;
                            //
                        } else if (0b1100_0000 <= first_byte and first_byte <= 0b1101_1111) {
                            char_bytes_length = 2;
                            // Rough filter to see if it .can_be_syllable_char
                            if (195 <= first_byte and first_byte <= 198 and
                                128 <= byte2 and byte2 <= 189)
                                char_type = .can_be_syllable_char;

                            if ((first_byte == 204 or first_byte == 205) and
                                128 <= byte2 and byte2 <= 163)
                                char_type = .can_be_syllable_char;
                            //
                        } else if (first_byte == 225) {
                            char_bytes_length = 3;
                            // Rough filter to see if it .can_be_syllable_char
                            if (byte2 == 186 or byte2 == 187)
                                char_type = .can_be_syllable_char;
                            //
                        } else if (0b1111_0000 <= first_byte and first_byte <= 0b1111_0111) {
                            char_bytes_length = 4;
                        } else {
                            char_bytes_length = 3;
                        }
                    } // got_error == null
                },
            }
            // Point the next_index pointer to the next VALID byte
            next_index = index + char_bytes_length;

            if (char_type == .space) {
                // in_token_zone bool variable let we know that if the current char is
                // belongs to a token or is SPACE delimitor
                if (in_token_zone) {
                    // Current char is SPACE delimitor so we are not in token zone anymore
                    in_token_zone = false;

                    // This is the first time we get out of token_zone
                    // so we end the current token at current byte index
                    const token = input_bytes[token_start_at..index];

                    // Then determine if the token is a (strick) valid VN syllable or not
                    // syllable.can_be_vietnamese is a loose filter so we do 3-more checks:

                    // Check #1: Filter out ascii-telex syllable like:
                    // car => cả, beer => bể ...
                    if (char_stream.tone == 0 and syllable.tone != ._none)
                        got_error = chars_utils.CharStreamError.ToneIsNotFromUtf8;

                    // Check #2: Filter out ascii-telex syllable like:
                    // awn => ăn, doo => dô
                    if (syllable.am_giua.hasMark() and !char_stream.has_mark)
                        got_error = chars_utils.CharStreamError.MarkIsNotFromUtf8;

                    // Check #3: Filter out prefix look like syllable but it's not:
                    // Mộtd, cuốiiii ...
                    if (char_stream.len > syllable.len())
                        got_error = chars_utils.CharStreamError.TooBigToBeSyllable;

                    // The final check is syllable.can_be_vietnamese
                    if (got_error != null or !syllable.can_be_vietnamese) {
                        // Copy token-as-it-is to output's ascii-telex
                        for (token) |b| {
                            self.text.appendTramsformedBytes(b);
                        }

                        // Insert token into a hash_map to know if we seen it before or not
                        const gop = try self.text.types_count.getOrPutValue(token, 0);
                        const token_existed = gop.value_ptr.* != 0;
                        gop.value_ptr.* += 1;

                        // Record out-of-vocabulary token
                        if (!token_existed) {
                            try self.recordOovToken(char_stream.hasMarkOrTone(), token);
                        }
                    } else {
                        // Record the newly converted ascii telex
                        const ascii_token = self.text.recordAndReturnTransform(char_stream, self.text.tokens_number);
                        // Insert ascii_token into a hash_map to know
                        // if we seen it before or not
                        const gop = try self.text.types_count.getOrPutValue(ascii_token, 0);
                        const token_existed = gop.value_ptr.* != 0;
                        gop.value_ptr.* += 1;

                        // Record syllable token
                        if (!token_existed) {
                            try self.recordSyllableToken(char_stream.pure_utf8, token);
                        }
                    }

                    char_stream.reset();
                    syllable.reset();
                    got_error = null;
                } // END if (in_token_zone)

                // Write trucate spaces and write one to output's ascii-telex
                if (prev_first_byte == ' ') {
                    if (first_byte == '\n')
                        self.text.overwriteCurrentTramsformedByte(first_byte);
                } else if (prev_first_byte != '\n') {
                    self.text.appendTramsformedBytes(first_byte);
                }
                // END char_type == .space
            } else {
                // char_type => .syllable_char or .can_be_syllable_char, or .others
                if (!in_token_zone) {
                    token_start_at = index;
                    in_token_zone = true;
                }

                if (got_error != null) continue;

                switch (char_type) {
                    .syllable_char => {
                        // a-zA-Z
                        char_stream.pushByte(first_byte, is_upper) catch |err| {
                            got_error = err;
                            continue;
                        };
                    },

                    .can_be_syllable_char => {
                        var char = try unicode.utf8Decode(input_bytes[index..next_index]);
                        char_stream.pushCharAndFirstByte(char, first_byte) catch |err| {
                            got_error = err;
                            continue;
                        };
                    },

                    else => {
                        got_error = chars_utils.CharStreamError.InvalidInputChar;
                        continue;
                    },
                }

                parsers.pushCharsToSyllable(print_nothing, &char_stream, &syllable);
            }
        } // End main loop
    }

    fn write_output_file(self: TextFileTokenizer, output_filename: []const u8) !void {
        // Open files to write transformed input data (final result)
        var output_file = try std.fs.cwd().createFile(output_filename, .{});
        defer output_file.close();
        _ = try output_file.writer().write(self.text.transformed_bytes[0..self.text.transformed_bytes_len]);
    }

    fn write_token_types_to_file(self: TextFileTokenizer, output_filename: []const u8) !void {
        var output_file = try std.fs.cwd().createFile(output_filename, .{});
        defer output_file.close();

        const max_token_len = 100;
        var buffer: [max_token_len + 15]u8 = undefined;
        const buff_slice = buffer[0..];

        var it = self.text.types_count.iterator();
        while (it.next()) |kv| {
            if (max_token_len < kv.key_ptr.*.len) {
                print("TOKEN TOO LONG: {s}\n", .{kv.key_ptr.*});
                continue;
            }
            const result = try std.fmt.bufPrint(buff_slice, "{d:10}  {s}\n", .{ kv.value_ptr.*, kv.key_ptr.* });
            _ = try output_file.writer().write(result);
        }
    }
};

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
    const max_lines_count: usize = if (args.nextPosix() != null) 1000 else 0;

    // Init and config a new TextFileTokenizer
    var tp: TextFileTokenizer = .{
        .init_allocator = std.heap.page_allocator,
        .max_lines_count = max_lines_count,
    };

    try tp.init(input_filename);
    defer tp.deinit();

    const init_ms = time.milliTimestamp() - start_time;
    const init_mins = @intToFloat(f32, init_ms) / 60000;
    print("\nInit Done! Duration {} ms => {d:.2} mins\n", .{ init_ms, init_mins });

    try tp.parse();

    const deinit_ms = time.milliTimestamp() - start_time;
    const deinit_mins = @intToFloat(f32, deinit_ms) / 60000;
    print("\nDeinit Start! Duration {} ms => {d:.2} mins\n", .{ deinit_ms, deinit_mins });

    try tp.write_output_file(output_filename);
    try tp.write_output_file("_output/telexified.txt");
    try tp.write_token_types_to_file("_output/types.txt");

    const end_time = time.milliTimestamp();
    print("\nend_time {}\n", .{end_time});
    const duration = end_time - start_time;
    const minutes = @intToFloat(f32, duration) / 60000;
    print("Duration {} ms => {d:.2} mins\n\n", .{ duration, minutes });
}

test "Telexify" {
    var tp: TextFileTokenizer = .{
        .init_allocator = std.testing.allocator,
        .max_lines_count = 1000, // guard, process maximum 1000 lines only
    };

    try tp.init("_input/corpus/corpus-title-sample.txt");
    defer tp.deinit();
    // errdefer tp.deinit();
    try tp.parse();
    try tp.write_output_file("_output/telexified/corpus-title-sample.txt");
    try tp.write_token_types_to_file("_output/telexified/corpus-title-sample_types.txt");
}
