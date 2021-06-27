const std = @import("std");
const print = std.debug.print;
const time = std.time;
const unicode = std.unicode;
const File = std.fs.File;

const parsers = @import("./src/parsers.zig");
const telex_utils = @import("./src/telex_utils.zig");
const chars_utils = @import("./src/chars_utils.zig");
const U2ACharStream = chars_utils.Utf8ToAsciiTelexAmTietCharStream;

fn printNothing(comptime fmt_str: []const u8, args: anytype) void {
    if (false)
        std.debug.print(fmt_str, args);
}

const TextProcessor = struct {
    init_allocator: *std.mem.Allocator,
    max_lines_count: usize = 0,

    arena: std.heap.ArenaAllocator = undefined,
    allocator: *std.mem.Allocator = undefined,

    input_file: File = undefined,
    input_bytes: []const u8 = undefined,

    output_bytes: []u8 = undefined,
    output_index: usize = undefined,

    syllables1_file: File = undefined,
    syllables2_file: File = undefined,
    oov1_file: File = undefined,
    oov2_file: File = undefined,

    tokens_count: std.StringHashMap(u32) = undefined,

    const syllables1_filename = "./_output/syllables1.txt";
    const syllables2_filename = "./_output/syllables2.txt";
    const oov1_filename = "./_output/oov1.txt";
    const oov2_filename = "./_output/oov2.txt";
    const max_doc_file_size = 600 * 1024 * 1024; // 600mb

    pub fn init(self: *TextProcessor, input_filename: []const u8) !void {
        self.arena = std.heap.ArenaAllocator.init(self.init_allocator);
        self.allocator = &self.arena.allocator;

        self.input_file = try std.fs.cwd().openFile(input_filename, .{ .read = true });
        self.input_bytes = try self.input_file.reader().readAllAlloc(self.allocator, max_doc_file_size);

        self.output_bytes = try self.allocator.alloc(u8, self.input_bytes.len + self.input_bytes.len / 3);
        self.tokens_count = std.StringHashMap(u32).init(self.allocator);

        // Open files to write intermediate results
        self.syllables1_file = try std.fs.cwd().createFile(syllables1_filename, .{});
        self.syllables2_file = try std.fs.cwd().createFile(syllables2_filename, .{});
        self.oov1_file = try std.fs.cwd().createFile(oov1_filename, .{});
        self.oov2_file = try std.fs.cwd().createFile(oov2_filename, .{});
    }

    pub fn deinit(self: *TextProcessor) void {
        self.input_file.close();

        self.syllables1_file.close();
        self.syllables2_file.close();

        self.oov1_file.close();
        self.oov2_file.close();

        self.allocator.free(self.input_bytes);
        self.allocator.free(self.output_bytes);

        self.tokens_count.deinit();
        self.arena.deinit();
    }

    const CharTypes = enum { syllable_char, can_be_syllable_char, space, others };

    pub fn parse(self: *TextProcessor) !void {
        @setRuntimeSafety(false);

        var syllables1_count: usize = 0;
        var syllables2_count: usize = 0;
        var oov1_count: usize = 0;
        var oov2_count: usize = 0;

        var syllables1_writer = std.io.bufferedWriter(self.syllables1_file.writer());
        var syllables2_writer = std.io.bufferedWriter(self.syllables2_file.writer());
        var oov1_writer = std.io.bufferedWriter(self.oov1_file.writer());
        var oov2_writer = std.io.bufferedWriter(self.oov2_file.writer());

        var char_stream = U2ACharStream.init();
        var syllable = parsers.Syllable.init();

        var index: usize = undefined;
        var next_index: usize = 0;
        var output_index: usize = 0;
        var token_start_at: usize = 0;

        var got_error: ?chars_utils.CharStreamError = null;
        var in_token_zone = true;

        var first_byte: u8 = undefined; // first byte of the utf-8 char
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
                            self.output_index = output_index;
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
                            self.output_bytes[output_index] = b;
                            output_index += 1;
                        }

                        // Insert token into a hash_map to know if we seen it before or not
                        const gop = try self.tokens_count.getOrPutValue(token, 0);
                        const token_existed = gop.value_ptr.* != 0;
                        gop.value_ptr.* += 1;

                        // Record out-of-vocabulary token
                        if (!token_existed) {
                            if (char_stream.hasMarkOrTone()) { // Write it to oov1.txt
                                _ = try oov1_writer.writer().write(token);
                                oov1_count += 1;
                                if (@rem(oov1_count, 10) == 0)
                                    _ = try oov1_writer.writer().write("\n")
                                else
                                    _ = try oov1_writer.writer().write("  ");
                            } else { // Write it oov2.txt
                                _ = try oov2_writer.writer().write(token);
                                oov2_count += 1;
                                if (@rem(oov2_count, 10) == 0)
                                    _ = try oov2_writer.writer().write("\n")
                                else
                                    _ = try oov2_writer.writer().write("  ");
                            }
                        }
                    } else {
                        // Convert input's utf-8 to output's ascii-telex
                        const ascii_token_start_at = output_index;
                        self.output_bytes[output_index] = '_'; // ▁'3:226:150:129
                        output_index += 1;

                        if (char_stream.is_upper_case) {
                            var i: usize = 0;
                            while (i < char_stream.len) : (i += 1) {
                                // Upper case the whole input bytes
                                self.output_bytes[output_index] =
                                    char_stream.buffer[i] & 0b11011111;
                                output_index += 1;
                            }
                            if (char_stream.tone != 0) {
                                self.output_bytes[output_index] =
                                    char_stream.tone & 0b11011111;
                                output_index += 1;
                            }
                        } else {
                            var i: usize = 0;
                            // Upper case the first letter
                            if (char_stream.is_title_case) {
                                self.output_bytes[output_index] =
                                    char_stream.buffer[0] & 0b11011111;
                                output_index += 1;
                                i = 1; // skip the first byte
                            }
                            // Copy the rest
                            while (i < char_stream.len) {
                                self.output_bytes[output_index] = char_stream.buffer[i];
                                i += 1;
                                output_index += 1;
                            }
                            if (char_stream.tone != 0) {
                                self.output_bytes[output_index] = char_stream.tone;
                                output_index += 1;
                            }
                        }
                        // END Convert input's utf-8 to output's ascii-telex

                        // Record the newly converted ascii telex
                        const ascii_token = self.output_bytes[ascii_token_start_at..output_index];
                        // Insert ascii telex tkn into a hash_map to know
                        // if we seen it before or not
                        const gop = try self.tokens_count.getOrPutValue(ascii_token, 0);
                        const token_existed = gop.value_ptr.* != 0;
                        gop.value_ptr.* += 1;

                        // Record syllable token
                        if (!token_existed) {
                            if (char_stream.pure_utf8) {
                                _ = try syllables1_writer.writer().write(token);
                                syllables1_count += 1;
                                if (@rem(syllables1_count, 12) == 0)
                                    _ = try syllables1_writer.writer().write("\n")
                                else
                                    _ = try syllables1_writer.writer().write("  ");
                            } else {
                                _ = try syllables2_writer.writer().write(token);
                                syllables2_count += 1;
                                if (@rem(syllables2_count, 12) == 0)
                                    _ = try syllables2_writer.writer().write("\n")
                                else
                                    _ = try syllables2_writer.writer().write("  ");
                            }
                        }
                        // END Record syllable token
                    }

                    char_stream.reset();
                    syllable.reset();
                    got_error = null;
                } // END if (in_token_zone)

                // Write space-as-it-is to output's ascii-telex
                self.output_bytes[output_index] = first_byte;
                output_index += 1;
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

                parsers.pushCharsToSyllable(printNothing, &char_stream, &syllable);
            }
        } // End main loop
        self.output_index = output_index;
    }

    fn write_output_file(self: TextProcessor, output_filename: []const u8) !void {
        // Open files to write transformed input data (final result)
        var output_file = try std.fs.cwd().createFile(output_filename, .{});
        defer output_file.close();
        _ = try output_file.writer().write(self.output_bytes[0..self.output_index]);
    }

    fn write_token_types_to_file(self: TextProcessor, output_filename: []const u8) !void {
        var output_file = try std.fs.cwd().createFile(output_filename, .{});
        defer output_file.close();

        const max_token_len = 100;
        var buffer: [max_token_len + 15]u8 = undefined;
        const buff_slice = buffer[0..];

        var it = self.tokens_count.iterator();
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

    // Init and config a new TextProcessor
    var tp: TextProcessor = .{
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
    try tp.write_token_types_to_file("_output/types.txt");

    const end_time = time.milliTimestamp();
    print("\nend_time {}\n", .{end_time});
    const duration = end_time - start_time;
    const minutes = @intToFloat(f32, duration) / 60000;
    print("Duration {} ms => {d:.2} mins\n\n", .{ duration, minutes });
}

test "Telexify" {
    var tp: TextProcessor = .{
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
