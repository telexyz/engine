const std = @import("std");
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
    input_bytes: []const u8,

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
    // transforms[i] will point to the transformed_bytes stream
    // How to use transformed_bytes is up's to the tokenizer (see telexify.zig)
    transformed_bytes: []u8 = undefined,

    // Allocated size
    transformed_bytes_size: usize = undefined,

    // Actually used, started with 0
    transformed_bytes_len: usize = 0,

    // Same tokens are counted as a type
    // Listing tytes along with its frequence will reveal intersting information
    alphabet_types_count: std.StringHashMap(u32) = undefined,
    delimiter_types_count: std.StringHashMap(u32) = undefined,

    // Try to predict maxium number of token to alloc mememory in advance
    estimated_tokens_number: usize = undefined,
    // Start the text with empty tokens list, hence tokens_number = 0
    tokens_number: usize = 0,

    // Used to estimate (maximum) tokens_number
    const AVG_BYTES_PER_TOKEN = 3;

    // A token can have multiple atributes:
    // Each attribute is re-presented by an enum
    // The final encoded attribute is re-presented by a struct
    pub const TokenAttributes = packed struct {
        category: TokenCategory,
        surrounded_by_spaces: TokenSurroundedBySpaces,
    };

    pub const TokenCategory = enum(u6) {
        others = 1, // + 2-bits => 4,5,6,7
        alphabet = 4, // + 2-bits => 16,17,18,19
        syllable = 5, // + 2-bits => 20,21,22,23
    };

    pub const TokenSurroundedBySpaces = enum(u2) {
        // Using 2-bits to describle
        none, // 0|0
        right, // 0|1
        left, // 1|0
        both, // 1|1
    };
    // Khi lưu ra text file ta sẽ lưu TokenAtrributes byte và space byte cùng nhau
    // Như vậy sẽ đạt được 2 mục đích:
    // 1/ tách từng token ra cho dễ nhìn
    // 2/ khi scan chuỗi, thì scan 2-bytes một, check bytes[0] <= 32 thì đó là boundary
    // Scan 2-bytes 1 sẽ cho tốc độ nhanh gấp 1.5 lần so với scan từng byte-1

    // Token attribute can be extracted from itself, \n for example
    pub fn isNewLineToken(token) bool {
        return token[0] == '\n';
    }

    pub fn init(self: *Text) !void {
        // Init will-be-used-from-now-on allocator from init_allocator
        self.arena = std.heap.ArenaAllocator.init(self.init_allocator);
        self.allocator = &self.arena.allocator;

        const input_bytes_size = self.input_bytes.len;
        var est_token_num = &self.estimated_tokens_number;
        est_token_num.* = input_bytes_size / AVG_BYTES_PER_TOKEN;

        // Init token list
        self.tokens = try self.allocator.alloc([]const u8, est_token_num.*);
        self.tokens_attrs = try self.allocator.alloc(TokenAttributes, est_token_num.*);

        // Init types count
        self.alphabet_types_count = std.StringHashMap(u32).init(self.allocator);
        self.delimiter_types_count = std.StringHashMap(u32).init(self.allocator);

        // Init transforms list
        self.transforms = try self.allocator.alloc([]const u8, est_token_num.*);

        // Init transformed_bytes, each token may have an additional byte at the begining
        // to present it's attribute so we need more memory than input_bytes
        self.transformed_bytes_size = input_bytes_size / 3;
        self.transformed_bytes = try self.allocator.alloc(u8, self.transformed_bytes_size);

        // Start empty token list and empty transfomed bytes
        self.tokens_number = 0;
        self.transformed_bytes_len = 0;
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
        self.tokens_number += 1;

        const gop = if (token_attrs.category == .alphabet)
            try self.alphabet_types_count.getOrPutValue(token, 0)
        else
            try self.delimiter_types_count.getOrPutValue(token, 0);

        gop.value_ptr.* += 1;
    }

    pub inline fn recordAndReturnTransform(self: *Text, char_stream: U2ACharStream, tkn_idx: usize) []const u8 {
        // Convert input's utf-8 to output's ascii-telex
        const transformed_token_start_at = self.transformed_bytes_len;
        // Set start char of ascii-telex to a special value
        // ▁'3:226:150:129 used by sentencepiece
        self.transformed_bytes[self.transformed_bytes_len] = 0b00000001;
        self.transformed_bytes_len += 1;

        if (char_stream.is_upper_case) {
            var i: usize = 0;
            while (i < char_stream.len) : (i += 1) {
                // Upper case the whole input bytes
                self.transformed_bytes[self.transformed_bytes_len] =
                    char_stream.buffer[i] & 0b11011111;
                self.transformed_bytes_len += 1;
            }
            if (char_stream.tone != 0) {
                self.transformed_bytes[self.transformed_bytes_len] =
                    char_stream.tone & 0b11011111;
                self.transformed_bytes_len += 1;
            }
        } else {
            var i: usize = 0;
            // Upper case the first letter
            if (char_stream.is_title_case) {
                self.transformed_bytes[self.transformed_bytes_len] =
                    char_stream.buffer[0] & 0b11011111;
                self.transformed_bytes_len += 1;
                i = 1; // skip the first byte
            }
            // Copy the rest
            while (i < char_stream.len) {
                self.transformed_bytes[self.transformed_bytes_len] = char_stream.buffer[i];
                i += 1;
                self.transformed_bytes_len += 1;
            }
            if (char_stream.tone != 0) {
                self.transformed_bytes[self.transformed_bytes_len] = char_stream.tone;
                self.transformed_bytes_len += 1;
            }
        }
        // self.transforms[tkn_idx] = self.transformed_bytes[transformed_token_start_at..self.transformed_bytes_len];
        // END Convert input's utf-8 to output's ascii-telex
        return self.transformed_bytes[transformed_token_start_at..self.transformed_bytes_len];
    }

    pub inline fn appendTramsformedBytes(self: *Text, b: u8) void {
        self.transformed_bytes[self.transformed_bytes_len] = b;
        self.transformed_bytes_len += 1;
    }

    pub inline fn overwriteCurrentTramsformedByte(self: *Text, b: u8) void {
        self.transformed_bytes[self.transformed_bytes_len] = b;
    }
};

test "Text" {
    var text = Text{
        .init_allocator = std.testing.allocator,
        .input_bytes = "thử nghiệm nhé, car nhà!",
    };
    try text.init();
    defer text.deinit();
}
