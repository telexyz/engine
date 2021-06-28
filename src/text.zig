const std = @import("std");
const File = std.fs.File;

const parsers = @import("./parsers.zig");
const chars_utils = @import("./chars_utils.zig");
const U2ACharStream = chars_utils.Utf8ToAsciiTelexAmTietCharStream;

pub const Text = struct {
    // Must be init when text is created
    init_allocator: *std.mem.Allocator,

    // Create arena's ArenaAllocator from init_allocator
    arena: std.heap.ArenaAllocator = undefined,

    // A shortcut to any allocator to switch to diff allocator if needed
    // for now it's &self.arena.allocator
    allocator: *std.mem.Allocator = undefined,

    // Done with boring allocators, now we describe the Text struct
    // First of all text is an input byte stream
    // we must initlized input_bytes somewhere and provide it to Text struct is created
    input_bytes: []const u8 = undefined,

    // The we split input bytes into a list of tokens
    // A toke is a slice of []const u8, that point to the original input bytes
    // (normally input byte are readed from a text file, corpus.txt for example)
    // Each tokens[i] slice will point to the original input_bytes
    tokens: [][]const u8 = undefined,
    tokens_attrs: []TokenAttributes = undefined,

    // A token can have multiple transforms:
    // For example ascii_transforms[i] is the ascii-telex transformation of tokens[i]
    // ascii_transforms should be used only if token is a VN syllable for sure,
    // other use-case should be considered carefully since we may loose
    // the original form of the input. For example:
    // "vớiiiii...." can be converted to ascii-telex "voowisiiii....",
    // but it not looked right for me. I think it we should keep original form.

    // We declare transforms[i] variable for general use-case
    transforms: [][]const u8 = undefined,

    // We'll need transformed_bytes stream as a data store for transforms slices
    // transforms[i] will point to a position in the transformed_bytes stream
    transformed_bytes: []u8 = undefined,

    // Allocated size, estimated based on input_bytes.len
    transformed_bytes_size: usize = undefined,

    // Actually used, started with 0
    transformed_bytes_len: usize = 0,

    // Same tokens are counted as a type
    // Listing tytes along with its frequence will reveal intersting information

    // Use data of input_bytes, pointed by tokens[i]
    alphabet_types: std.StringHashMap(TypeInfo) = undefined,
    // Use data of input_bytes, pointed by tokens[i]
    nonalpha_types: std.StringHashMap(TypeInfo) = undefined,

    // Use data of transformed_bytes, pointed by transforms[i]
    syllable_types: std.StringHashMap(u32) = undefined, // syllable.toLower =
    syllower_types: std.StringHashMap(u32) = undefined, // syllower
    // Data buffer for syllower_types
    syllower_bytes: []u8 = undefined,
    syllower_bytes_size: usize = undefined,
    syllower_bytes_len: usize = 0,

    // Try to predict maxium number of token to alloc mememory in advance
    estimated_tokens_number: usize = undefined,
    // Start the text with empty tokens list, hence tokens_number = 0
    tokens_number: usize = 0,
    processed_types_count: usize = 0,
    // To skip sleep time
    tokens_number_finalized: bool = false,

    init_from_file = false,
    // Used to estimate (maximum) tokens_number
    const AVG_BYTES_PER_TOKEN = 3;
    const MAX_INPUT_FILE_SIZE = 600 * 1024 * 1024; // 600mb
    const TEXT_DICT_FILE_SIZE = 1024 * 1024; // 1mb
    const BUFF_SIZE = 100; // incase input is small, estimated fail, so need buffer

    pub const TypeInfo = struct {
        count: u32 = 0,
        transform: []const u8 = undefined,
        category: TokenCategory = ._none,
    };

    // A token can have multiple atributes:
    // Each attribute is re-presented by an enum
    // The final encoded attribute is re-presented by a struct
    pub const TokenAttributes = packed struct {
        surrounded_by_spaces: TokenSurroundedBySpaces,
        category: TokenCategory,
    };

    pub const TokenCategory = enum(u6) {
        // Dùng được 27 invisible ascii chars, 1-8,11, 12,15-31
        // 3 main token categoried, used to write to disk as token's attrs
        //         0  //  + 2-bits  => 00,01,02,03 + 1 => \x01\x02\x03\x04
        //         1  //  + 2-bits  => 04,05,06,07 + 1 => \x05\x06\x07\x08
        //         2  //  + 0x11    =>       10    + 1 => \x0b
        //         3  //  + 0x00,11 => 12       15     => \x0c\x0f
        syllable = 4, //  + 2-bits  => 16,17,18,19     => \x10\x11\x12\x13
        marktone = 5, //  + 2-bits  => 20,21,22,23     => \x14\x15\x16\x17
        alphabet = 6, //  + 2-bits  => 24,25,26,27     => \x18\x19\x1a\x1b
        nonalpha = 7, //  + 2-bits  => 28,29,30,31     => \x1c\x1d\x1e\x1f
        // Supplement category ids 8-63
        // used as an intialized/temp values / need to be processed / state machine
        _none = 8, // initial state
    };

    pub const TokenSurroundedBySpaces = enum(u2) {
        // Use 2-bits to describle
        none, //  0|0
        right, // 0|1
        left, //  1|0
        both, //  1|1
    };
    // Khi lưu ra text file ta sẽ lưu TokenAtrributes byte và space byte cùng nhau
    // Như vậy sẽ đạt được 2 mục đích:
    // 1/ tách từng token ra cho dễ nhìn
    // 2/ khi scan chuỗi, thì scan 2-bytes một, check bytes[0] <= 32 thì đó là boundary
    // Scan 2-bytes 1 sẽ cho tốc độ nhanh gấp 1.5 lần so với scan từng byte-1

    pub fn initFromFile(self: *Text, input_filename: []const u8) !void {
        var input_file = try std.fs.cwd().openFile(input_filename, .{ .read = true });
        defer input_file.close();
        var input_bytes = try input_file.reader().readAllAlloc(self.allocator, MAX_INPUT_FILE_SIZE);
        initFromInputBytes(input_bytes);
    }

    pub fn initFromInputBytes(self: *Text, input_bytes: []const u8) !void {
        // Init will-be-used-from-now-on allocator from init_allocator
        self.arena = std.heap.ArenaAllocator.init(self.init_allocator);
        self.allocator = &self.arena.allocator;
        self.input_bytes = input_bytes;

        const input_bytes_size = self.input_bytes.len;
        var est_token_num = &self.estimated_tokens_number;
        est_token_num.* = input_bytes_size / AVG_BYTES_PER_TOKEN + BUFF_SIZE;

        // Init token list
        self.tokens = try self.allocator.alloc([]const u8, est_token_num.*);
        self.tokens_attrs = try self.allocator.alloc(TokenAttributes, est_token_num.*);

        // Init types count
        self.alphabet_types = std.StringHashMap(TypeInfo).init(self.allocator);
        self.nonalpha_types = std.StringHashMap(TypeInfo).init(self.allocator);
        self.syllable_types = std.StringHashMap(u32).init(self.allocator);

        // Init transforms list
        self.transforms = try self.allocator.alloc([]const u8, est_token_num.*);

        // Init transformed_bytes, each token may have an additional byte at the
        // begining to store it's attribute so we need more memory than input_bytes
        self.transformed_bytes_size = input_bytes_size + input_bytes_size / 5 + BUFF_SIZE;
        self.transformed_bytes = try self.allocator.alloc(u8, self.transformed_bytes_size);

        // Init syllower...
        self.syllower_types = std.StringHashMap(u32).init(self.allocator);
        self.syllower_bytes_size = TEXT_DICT_FILE_SIZE;
        self.syllower_bytes = try self.allocator.alloc(u8, self.syllower_bytes_size);

        // Start empty token list and empty transfomed bytes
        self.tokens_number = 0;
        self.transformed_bytes_len = 0;
        self.syllower_bytes_len = 0;
    }
    pub fn deinit(self: *Text) void {
        // Since we use ArenaAllocator, simply deinit arena itself to
        // free all allocated memories
        self.arena.deinit();
    }

    pub fn countToken(self: *Text, token: []const u8, token_attrs: TokenAttributes) !void {
        // Insert token into a hash_map to know if we seen it before or not
        // const token = self.input_bytes[token_start..token_end];
        self.tokens[self.tokens_number] = token;
        self.tokens_attrs[self.tokens_number] = token_attrs;
        // Default, transform to itself :)
        self.transforms[self.tokens_number] = token;

        const gop = if (token_attrs.category == .nonalpha)
            try self.nonalpha_types.getOrPutValue(token, TypeInfo{})
        else
            try self.alphabet_types.getOrPutValue(token, TypeInfo{});

        gop.value_ptr.*.count += 1;

        // increare only when counter is finalized since other threads are watching
        self.tokens_number += 1;
    }

    pub fn saveAndReturnTrans(self: *Text, char_stream: U2ACharStream) []const u8 {
        // Convert input's utf-8 to output's ascii-telex
        const bytes_len = &self.transformed_bytes_len;
        const trans_start_at = bytes_len.*;

        if (char_stream.is_upper_case) {
            var i: usize = 0;
            while (i < char_stream.len) : (i += 1) {
                // Upper case the whole input bytes
                self.transformed_bytes[bytes_len.*] =
                    char_stream.buffer[i] & 0b11011111;
                bytes_len.* += 1;
            }
            if (char_stream.tone != 0) {
                self.transformed_bytes[bytes_len.*] =
                    char_stream.tone & 0b11011111;
                bytes_len.* += 1;
            }
        } else {
            var i: usize = 0;
            // Upper case the first letter
            if (char_stream.is_title_case) {
                self.transformed_bytes[bytes_len.*] =
                    char_stream.buffer[0] & 0b11011111;
                bytes_len.* += 1;
                i = 1; // skip the first byte
            }
            // Copy the rest
            while (i < char_stream.len) {
                self.transformed_bytes[bytes_len.*] = char_stream.buffer[i];
                i += 1;
                bytes_len.* += 1;
            }
            if (char_stream.tone != 0) {
                self.transformed_bytes[bytes_len.*] = char_stream.tone;
                bytes_len.* += 1;
            }
        }
        // END Convert input's utf-8 to output's ascii-telex
        return self.transformed_bytes[trans_start_at..bytes_len.*];
    }

    const PAD = "                 ";
    pub fn telexifyAlphabetTokens(self: *Text) void {
        @setRuntimeSafety(false);
        var char_stream = U2ACharStream.new();
        var prev_percent: u64 = 0;

        const max_sleeps: u8 = 1;
        const sleep_time: u64 = 600_000_000; // nanosec
        var sleeps_count: u8 = 0;

        var i: *usize = &self.processed_types_count;
        while (i.* <= self.tokens_number) : (i.* += 1) {
            // Check if reach the end of tokens list
            if (i.* == self.tokens_number) {
                // If no more tokens for sure then return
                if (self.tokens_number_finalized) return;
                // BEGIN waiting for new tokens (all tokens is processed)
                while (sleeps_count < max_sleeps and i.* == self.tokens_number) {
                    std.time.sleep(sleep_time);
                    sleeps_count += 1;
                    std.debug.print("{s}... wait new tokens\n", .{PAD});
                }
                if (i.* == self.tokens_number) {
                    // No new token and timeout
                    return;
                } else {
                    // Reset sleep counter and continue
                    sleeps_count = 0;
                }
            } // END waiting for new tokens

            // Init token and it's attributes shortcuts
            var token = self.tokens[i.*];

            // is NewLine token
            if (token[0] == '\n') {
                self.transformed_bytes[self.transformed_bytes_len] = '\n';
                self.transformed_bytes_len += 1;

                // Show token parsing progress
                const percent: u64 = if (!self.tokens_number_finalized)
                    (100 * self.transformed_bytes_len) / self.transformed_bytes_size
                else
                    (100 * i.*) / self.tokens_number;

                if (percent > prev_percent) {
                    prev_percent = percent;
                    if (@rem(percent, 3) == 0)
                        std.debug.print("{s}{d}% Syllabling\n", .{ PAD, percent });
                }

                continue;
            }

            //  and it's attributes shortcuts
            var attrs = &self.tokens_attrs[i.*];
            var token_written = false;

            // Reserver first-byte to write token attrs
            const firt_byte_index = self.transformed_bytes_len;
            self.transformed_bytes_len += 1;

            if (attrs.category != .nonalpha) {
                // Since token is alphabet, it's alphabet_types[i]'s info must existed
                const type_info = self.alphabet_types.getPtr(token).?;

                if (type_info.*.category == ._none) {
                    // Not transformed yet
                    char_stream.reset();
                    const syllable = parsers.parseTokenToGetSyllable(
                        true,
                        printNothing,
                        &char_stream,
                        token,
                    );

                    if (syllable.can_be_vietnamese) {
                        // First time convert type to syllable
                        type_info.*.category = .syllable;
                        // Point token value to it's syllable trans
                        token = self.saveAndReturnTrans(char_stream);
                        type_info.*.transform = token;
                        // First token point to this syllable trans don't need
                        // to write data, later, mark token_written = true to know
                        token_written = true;

                        // Record and count syllable
                        const count = type_info.*.count;
                        const gop =
                            self.syllable_types.getOrPutValue(token, 0) catch null;
                        gop.?.value_ptr.* += count;

                        // Take syllable to create lowercase version
                        self.saveAndCountLowerSyllable(token, count) catch unreachable;
                    } else {

                        // For non-syllable, attrs.category can only
                        // be .alphabet or .marktone
                        type_info.*.category = attrs.category;

                        // if (char_stream.hasMarkOrTone()) {
                        //     type_info.*.category = .marktone;
                        // } else {
                        //     var n = char_stream.len;
                        //     if (char_stream.tone != 0) n += 1;

                        //     type_info.*.category = if (n >= token.len)
                        //         TokenCategory.alphabet
                        //     else
                        //         attrs.category;
                        // }

                        // DEBUG
                        // if (token[0] == 'c' and token[1] == 'p') {
                        //     std.debug.print("{s} => {}; {s} => {}\n\n", .{ token, attrs.category, char_stream.toStr(), char_stream.hasMarkOrTone() });
                        //     std.debug.print("\n{s} {s} {s} {s}\n\n", .{ self.tokens[i.* + 1], self.tokens[i.* + 2], self.tokens[i.* + 3], self.tokens[i.* + 4] });
                        // }
                    }
                }

                if (type_info.*.category == .syllable) {
                    attrs.category = .syllable;
                    // Point token value to it's syllable trans
                    token = type_info.*.transform;
                    self.transforms[i.*] = token;
                }
            } // attrs.category == .alphabet

            if (!token_written) {
                // write original token it's is not syllable
                for (token) |b| {
                    self.transformed_bytes[self.transformed_bytes_len] = b;
                    self.transformed_bytes_len += 1;
                }
            }
            // Write attrs at the begin of token's ouput stream
            self.transformed_bytes[firt_byte_index] = @bitCast(u8, attrs.*);
        }
    }

    pub fn saveAndCountLowerSyllable(self: *Text, token: []const u8, count: u32) !void {
        const next = self.syllower_bytes_len + token.len;
        const lsyll = self.syllower_bytes[self.syllower_bytes_len..next];
        // To lower
        for (token) |c, i| {
            lsyll[i] = c | 0b00100000;
        }
        const gop = try self.syllower_types.getOrPutValue(lsyll, 0);
        gop.value_ptr.* += count;

        self.syllower_bytes_len = next;
    }

    pub fn removeSyllablesFromAlphabetTypes(self: *Text) void {
        if (!self.tokens_number_finalized) return;

        var it = self.alphabet_types.iterator();
        while (it.next()) |kv| {
            if (kv.value_ptr.*.category == .syllable) {
                _ = self.alphabet_types.remove(kv.key_ptr.*);
            }
        }
    }
};

fn printNothing(comptime fmt_str: []const u8, args: anytype) void {
    if (false)
        std.debug.print(fmt_str, args);
}

test "Text" {
    var text = Text{
        .init_allocator = std.testing.allocator,
        .input_bytes = "Cả nhà ơi, thử nghiệm nhé, cả nhà !",
    };

    try text.init();
    defer text.deinit();

    // Text is a struct with very basic function
    // It's up to tokenizer to split the text and assign value to tokens[i]
    var it = std.mem.tokenize(text.input_bytes, " ");
    var token = it.next();
    var token_attrs: Text.TokenAttributes = .{
        .category = .alphabet,
        .surrounded_by_spaces = .both,
    };
    try text.countToken(token.?, token_attrs);
    try std.testing.expect(text.tokens_number == 1);
    try std.testing.expectEqualStrings(text.tokens[0], "Cả");

    try text.countToken(it.next().?, token_attrs);
    try text.countToken(it.next().?, token_attrs);

    const thread = try std.Thread.spawn(Text.telexifyAlphabetTokens, &text);

    while (it.next()) |tkn| {
        try text.countToken(tkn, token_attrs);
    }

    thread.wait();
    text.telexifyAlphabetTokens();

    try std.testing.expect(text.tokens_number == 9);
    try std.testing.expectEqualStrings(text.tokens[7], "nhà");
    try std.testing.expect(text.alphabet_types.get("nhà").?.count == 2);
    try std.testing.expect(text.alphabet_types.get("xxx") == null);
    try std.testing.expect(text.alphabet_types.count() == 8);
    try std.testing.expect(text.nonalpha_types.count() == 0);
}
