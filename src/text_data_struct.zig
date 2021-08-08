const std = @import("std");
const File = std.fs.File;

const syllable_data_structs = @import("./syllable_data_structs.zig");
const Syllable = syllable_data_structs.Syllable;
const text_utils = @import("./text_utils.zig");
const telex_char_stream = @import("./telex_char_stream.zig");
const U2ACharStream = telex_char_stream.Utf8ToAsciiTelexCharStream;

pub const Text = struct {
    // Keep origin data as-much-as-possible
    keep_origin_amap: bool = true,
    convert_mode: u8 = 1, // dense
    prev_token_is_vi: bool = true,

    // Must be init when text is created
    init_allocator: *std.mem.Allocator,

    // Create arena's ArenaAllocator from init_allocator
    arena: std.heap.ArenaAllocator = undefined,
    allocator: *std.mem.Allocator = undefined,
    allocator_initialized: bool = false,

    // Done with boring allocators, now we describe the Text struct
    // First of all text is an input byte stream
    // we must initlized input_bytes somewhere and provide it to Text struct is created
    input_bytes: []const u8 = undefined,
    can_free_input_bytes: bool = false,

    // A token can have multiple transforms:
    // For example ascii_transforms[i] is the ascii-telex transformation of tokens[i]
    // ascii_transforms should be used only if token is a VN syllable for sure,
    // other use-case should be considered carefully since we may loose
    // the original form of the input. For example:
    // "vớiiiii...." can be converted to ascii-telex "vowisiiii....",
    // but it not looked right for me. I think it we should keep original form.
    // Same tokens counted to type, we will save transform in TypeInfo

    // Same tokens are counted as a type
    // Listing tytes along with its frequence will reveal intersting information

    // Use data of alphabet_bytes and nonalpha_bytes
    alphabet_types: std.StringHashMap(TypeInfo) = undefined,
    nonalpha_types: std.StringHashMap(u32) = undefined,

    // Use data of syllable_bytes and syllow00_bytes
    syllow00_types: std.StringHashMap(TypeInfo) = undefined, // = syllable.toLower -mark - tone
    syllable_types: std.StringHashMap(TypeInfo) = undefined,

    // Data buffer for both alphabet_types and nonalpha_types
    alphabet_bytes: []u8 = undefined,
    alphabet_bytes_len: TransOffset = 0,

    nonalpha_bytes: []u8 = undefined,
    nonalpha_bytes_len: TransOffset = 0,

    // Data buffer for syllable_types
    syllable_bytes: []u8 = undefined,
    syllable_bytes_len: TransOffset = 0,

    // Data buffer for syllow00_types
    syllow00_bytes: []u8 = undefined,
    syllow00_bytes_len: usize = 0,

    // Start the text with empty tokens list, hence tokens_number = 0
    tokens_number: usize = 0,
    parsed_input_bytes: usize = 0,
    parsed_tokens_number: usize = 0,
    tokens_number_finalized: bool = false,

    // Try to predict maxium number of token to alloc mememory in advance
    estimated_tokens_num: usize = undefined,
    tokens_infos: []TokenInfo = undefined,

    // For 1Gb text input (1024*1024*1024 bytes)
    // estimated_tokens_num = 214 * 1024 * 1024 (1024*1024*1024 / 4.8)
    // Mem allocated to tokens_infos = (214 * 6) * 1024 * 1024 = 2562 MB (1.2Gb)

    pub const TokenInfo = struct { //         Total 6-bytes
        trans_offset: TransOffset = undefined, //   3-bytes
        attrs: TokenAttributes = undefined, //      1-byte
        syllable_id: Syllable.UniqueId = 0, //      2-bytes

        pub inline fn trans_ptr(self: TokenInfo, text: *Text) [*]u8 {
            const buff = switch (self.attrs.category) {
                .nonalpha => text.nonalpha_bytes,
                .syllmark, .syll0m0t => text.syllable_bytes,
                else => text.alphabet_bytes,
            };
            return buff.ptr + self.trans_offset;
        }

        pub inline fn trans_slice(self: TokenInfo, text: *Text) []const u8 {
            var ptr = self.trans_ptr(text);
            return ptr[0..double_0_trans_len(ptr)];
        }

        pub inline fn isSyllable(self: TokenInfo) bool {
            return self.syllable_id != 0;
        }
    };

    const ONE_MB = 1024 * 1024;
    const MAX_INPUT_FILE_SIZE = 2048 * ONE_MB; // 1336 ~ 1.3Gb
    const BUFF_SIZE = 256; // incase input is small, estimated not correct

    pub inline fn double_0_trans_len(ptr: [*]u8) usize {
        var n: usize = 2;
        while (ptr[n] != 0) : (n += 2) {}
        if (ptr[n - 1] == 0) n -= 1;
        return n;
    }

    pub const TransOffset = u24; //= 2^4 * 2^10 * 2^10 = 16 * 1024 * 1024 = 16Mb
    pub const TypeInfo = struct { //         Total 10-bytes (old struct 23-bytes)
        count: u32 = 0, //                          4-bytes
        trans_offset: TransOffset = undefined, //   3-bytes
        category: TokenCategory = undefined, //     1-bytes
        syllable_id: Syllable.UniqueId = 0, //      2-bytes

        pub inline fn trans_ptr(self: TypeInfo, text: *Text) [*]u8 {
            return text.syllable_bytes.ptr + self.trans_offset;
        }

        pub inline fn trans_slice(self: TypeInfo, text: *Text) []const u8 {
            const ptr = text.syllable_bytes.ptr + self.trans_offset;
            return ptr[0..double_0_trans_len(ptr)];
        }

        pub inline fn isSyllable(self: TypeInfo) bool {
            return self.syllable_id != 0;
        }

        pub inline fn haveMarkTone(self: TypeInfo) bool {
            return self.category == .syllmark or self.category == .alphmark;
        }
    };

    // A token can have multiple atributes:
    // Each attribute is re-presented by an enum
    // The final encoded attribute is re-presented by a struct
    pub const TokenAttributes = packed struct {
        surrounded_by_spaces: TokenSurroundedBySpaces,
        category: TokenCategory,

        pub inline fn spaceAfter(self: TokenAttributes) bool {
            return self.surrounded_by_spaces == .right or
                self.surrounded_by_spaces == .both;
        }

        pub inline fn isSyllable(self: TokenAttributes) bool {
            return self.category == .syllmark or self.category == .syll0m0t;
        }

        pub inline fn haveMarkTone(self: TypeInfo) bool {
            return self.category == .syllmark or self.category == .alphmark;
        }

        pub inline fn toByte(self: TokenAttributes) u8 {
            const byte = @bitCast(u8, self);
            if (byte < 12) return byte + 1;
            return byte;
        }

        pub inline fn newFromByte(byte: u8) TokenAttributes {
            if (byte < 12) byte -= 1;
            return @bitCast(TokenAttributes, byte);
        }
    };

    pub const TokenCategory = enum(u6) {
        // Dùng được 27 invisible ascii chars, 1-8,11, 12,15-31
        // 3 main token categoried, used to write to disk as token's attrs
        nonalpha = 0, //  + 2-bits  => 00,01,02,03 + 1 => \x01\x02\x03\x04
        // Avoid slot 1 if possible since it don't show as space in klogg app
        //         1, //  + 2-bits  => 04,05,06,07 + 1 => \x05\x06\x07\x08
        //         2, //  + 0x11    =>       10    + 1 => \x0b
        //         3, //  + 0x00,11 => 12       15     => \x0c\x0f
        alphmark = 4, //  + 2-bits  => 16,17,18,19     => \x10\x11\x12\x13
        alph0m0t = 5, //  + 2-bits  => 20,21,22,23     => \x14\x15\x16\x17
        syllmark = 6, //  + 2-bits  => 24,25,26,27     => \x18\x19\x1a\x1b
        syll0m0t = 7, //  + 2-bits  => 28,29,30,31     => \x1c\x1d\x1e\x1f
        // Supplement category ids 8-63
        // used as an intialized/temp values / need to be processed / state machine
        can_be_syllable = 8,
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
        self.initAllocatorIfNeeded();
        var input_file = try std.fs.cwd().openFile(input_filename, .{ .read = true });
        defer input_file.close();
        var input_bytes = try input_file.reader().readAllAlloc(self.init_allocator, MAX_INPUT_FILE_SIZE);
        self.can_free_input_bytes = true;
        try self.initFromInputBytes(input_bytes);
    }

    fn initAllocatorIfNeeded(self: *Text) void {
        if (self.allocator_initialized) return;
        self.arena = std.heap.ArenaAllocator.init(self.init_allocator);
        self.allocator = &self.arena.allocator;
        self.allocator_initialized = true;
    }

    pub fn initFromInputBytes(self: *Text, input_bytes: []const u8) !void {
        self.initAllocatorIfNeeded();
        self.input_bytes = input_bytes;

        const input_bytes_size = self.input_bytes.len;
        self.estimated_tokens_num = (input_bytes_size * 10) / 45;
        self.estimated_tokens_num += BUFF_SIZE;

        // Init tokens infos list
        self.tokens_infos = try self.allocator.alloc(
            TokenInfo,
            self.estimated_tokens_num,
        );

        // Init types count
        self.alphabet_types = std.StringHashMap(TypeInfo).init(self.allocator);
        self.nonalpha_types = std.StringHashMap(u32).init(self.allocator);
        self.syllable_types = std.StringHashMap(TypeInfo).init(self.allocator);

        self.alphabet_bytes = try self.allocator.alloc(u8, 16 * ONE_MB);
        self.nonalpha_bytes = try self.allocator.alloc(u8, 16 * ONE_MB);
        self.alphabet_bytes_len = 0;
        self.nonalpha_bytes_len = 0;

        // Init syllable...
        self.syllable_bytes = try self.allocator.alloc(u8, ONE_MB);
        self.syllable_bytes_len = 0;

        // Init syllower...
        self.syllow00_types = std.StringHashMap(TypeInfo).init(self.allocator);
        self.syllow00_bytes = try self.allocator.alloc(u8, ONE_MB);
        self.syllow00_bytes_len = 0;

        // Start empty token list and empty transfomed bytes
        self.tokens_number = 0;
    }

    pub fn free_input_bytes(self: *Text) void {
        if (self.can_free_input_bytes) {
            self.init_allocator.free(self.input_bytes);
            self.can_free_input_bytes = false;
        }
    }

    pub fn deinit(self: *Text) void {
        self.free_input_bytes();
        // Since we use ArenaAllocator, simply deinit arena itself to
        // free all allocated memories
        self.arena.deinit();
    }

    pub fn getToken(self: *Text, n: usize) []const u8 {
        return self.tokens_infos[n].trans_slice(self);
    }

    inline fn copyToken(token: []const u8, token_info: *TokenInfo, bytes_ptr: [*]u8, bytes_len: *TransOffset) []const u8 {
        var token_len = @intCast(Text.TransOffset, token.len);
        var token_ptr = bytes_ptr + bytes_len.*;

        const copied_token = token_ptr[0..token_len];

        // Copy input _token to token_bytes
        for (token) |byte| {
            token_ptr.* = byte;
            token_ptr += 1;
        }

        // Add double 0 terminators
        token_ptr.* = 0;
        token_ptr += 1;
        token_ptr.* = 0;

        // Remember copied one index in token_info.trans_offset
        token_info.trans_offset = bytes_len.*;

        // Then increase token_bytes_len to reach the end of token_bytes
        if (bytes_len.* > 16_777_128) {
            std.debug.print("\n{}", .{bytes_len.*});
        }
        bytes_len.* += token_len + 2; // <= double 0 terminators

        // Return copied token
        return copied_token;
    }

    pub fn recordToken(self: *Text, _token: []const u8, attrs: TokenAttributes, then_parse_syllable: bool) !void {
        // Guarding
        if (self.tokens_number > self.estimated_tokens_num) {
            std.debug.print("!!! Need to adjust Text.estimated_tokens_num !!!", .{});
            unreachable;
        }

        // Init token_info
        const token_info = &self.tokens_infos[self.tokens_number];
        token_info.attrs = attrs;

        // Token transit place holder
        var token: []const u8 = undefined;

        if (attrs.category == .nonalpha) {
            // nonalpha token
            const entry = self.nonalpha_types.getEntry(_token);
            const start_ptr = self.nonalpha_bytes.ptr;

            if (entry == null) {
                // Write _token to token_bytes, update token_info.trans_offset
                token = copyToken(_token, token_info, start_ptr, &self.nonalpha_bytes_len);
                try self.nonalpha_types.put(token, 1);
                //
            } else {
                //
                const kv = entry.?;
                token = kv.key_ptr.*;
                token_info.trans_offset = @intCast(TransOffset, @ptrToInt(kv.key_ptr.*.ptr) - @ptrToInt(start_ptr));
                kv.value_ptr.* += 1;
            }
            //
        } else { // alphabet token
            //
            const entry = self.alphabet_types.getEntry(_token);
            // std.debug.print("\ntoken: {s}", .{_token});//DEBUG
            const start_ptr = self.alphabet_bytes.ptr;
            var kv: std.StringHashMap(TypeInfo).Entry = undefined;

            if (entry == null) {
                // Write _token to token_bytes, update token_info.trans_offset
                token = copyToken(_token, token_info, start_ptr, &self.alphabet_bytes_len);
                kv = try self.alphabet_types.getOrPutValue(token, TypeInfo{
                    .count = 1,
                    .category = if (token.len <= U2ACharStream.MAX_LEN) .can_be_syllable else attrs.category,
                });
                //
            } else {
                //
                kv = entry.?;
                token = kv.key_ptr.*;
                token_info.trans_offset = @intCast(TransOffset, @ptrToInt(kv.key_ptr.*.ptr) - @ptrToInt(start_ptr));
                kv.value_ptr.count += 1;
            }

            if (then_parse_syllable and token.len <= U2ACharStream.MAX_LEN) {
                const type_info = kv.value_ptr;

                text_utils.token2Syllable(token, attrs, type_info, self);

                if (type_info.isSyllable()) {
                    token_info.attrs.category = type_info.category;
                    token_info.syllable_id = type_info.syllable_id;
                    token_info.trans_offset = type_info.trans_offset;
                }
            }
        }

        // increare tokens_number only when everything is finalized
        self.tokens_number += 1;
        if (then_parse_syllable) self.parsed_tokens_number = self.tokens_number;
    }

    pub fn processAlphabetTypes(self: *Text) !void {
        var it = self.alphabet_types.iterator();
        while (it.next()) |kv|
            if (kv.value_ptr.isSyllable())
                try self.countSyllableAndSyllow0t(kv.value_ptr.trans_slice(self), kv.value_ptr);
    }

    pub fn countSyllableAndSyllow0t(self: *Text, syllable: []const u8, type_info: *const Text.TypeInfo) !void {
        // std.debug.print("\nSyllable: \"{s}\"", .{syllable});//DEBUG
        // Record and count syllable
        const gop1 = try self.syllable_types.getOrPutValue(syllable, TypeInfo{ .category = type_info.category });
        gop1.value_ptr.count += type_info.count;

        // Convert syllable to syllow00
        var i: u8 = if (syllable[0] == '^') 1 else 0;
        if (i == 1 and (syllable[1] == '^' or syllable[1] == 32)) i = 2;
        if (i == 2 and syllable[2] == 32) i = 3;

        // Remove tone "[sfrxj]"
        var n = syllable.len - 1;
        switch (syllable[n]) {
            's', 'f', 'r', 'x', 'j' => n -= 1,
            else => {},
        }
        // Remove mark
        switch (syllable[n]) {
            'w', 'z' => n -= 1,
            else => {},
        }

        var next = self.syllow00_bytes_len;
        while (i <= n) : (i += 1) {
            self.syllow00_bytes[next] = syllable[i];
            next += 1;
        }

        const syllow00 = self.syllow00_bytes[self.syllow00_bytes_len..next];
        self.syllow00_bytes_len = next;

        const gop2 = try self.syllow00_types.getOrPutValue(syllow00, TypeInfo{ .category = type_info.category });
        gop2.value_ptr.count += type_info.count;
    }
};

test "Text" {
    var text = Text{
        .init_allocator = std.testing.allocator,
    };

    try text.initFromInputBytes("Cả nhà đơi , thử nghiệm nhé , cả nhà ! TAQs");
    defer text.deinit();

    // Text is a struct with very basic function
    // It's up to tokenizer to split the text and assign value to tokens
    // Here is the simplest tokenizer based on space delimiter
    // std.mem.tokenize is a Zig standard library function to deal with byte stream
    var it = std.mem.tokenize(u8, text.input_bytes, " ");
    var token = it.next();
    var attrs: Text.TokenAttributes = .{
        .category = .alphmark,
        .surrounded_by_spaces = .both,
    };

    if (false) {
        try text.recordToken(token.?, attrs, false);
        try std.testing.expect(text.tokens_number == 1);
        try std.testing.expectEqualStrings(text.getToken(0), "Cả");
        try text.recordToken(it.next().?, attrs, false);
        try text.recordToken(it.next().?, attrs, false);

        const thread = try std.Thread.spawn(.{}, text_utils.parseTokens, .{&text});
        while (it.next()) |tkn| try text.recordToken(tkn, attrs, false);
        text.tokens_number_finalized = true;
        thread.join();
        text_utils.parseTokens(&text);
    } else {
        try text.recordToken(token.?, attrs, true);
        try std.testing.expect(text.tokens_number == 1);
        try std.testing.expectEqualStrings(text.getToken(0), "^ca|r");
        try text.recordToken(it.next().?, attrs, true);
        try text.recordToken(it.next().?, attrs, true);
        while (it.next()) |tkn| try text.recordToken(tkn, attrs, true);
        text.tokens_number_finalized = true;
    }

    try std.testing.expect(text.tokens_number == 12);
    try std.testing.expectEqualStrings(text.getToken(9), "nha|f");
    try std.testing.expect(text.alphabet_types.get("!").?.count == 1);
    try std.testing.expect(text.alphabet_types.get(",").?.count == 2);
    try std.testing.expect(text.alphabet_types.get("TAQs").?.count == 1);
    try std.testing.expect(text.alphabet_types.get("xxx") == null);

    //  1s 2s  3s  1a 4s  5s     6s  1a 1s 2s  2a 3a
    // "Cả nhà đơi ,  thử nghiệm nhé ,  cả nhà !  TAQs"

    try text.processAlphabetTypes();
    try std.testing.expect(text.alphabet_types.count() == 10);

    // std.debug.print("\n{}\n", .{text.syllable_types.get("nha|f").?.count});
    // std.debug.print("\n{}\n\n", .{text.syllow00_types.get("ca|").?.count});
    try std.testing.expect(text.syllable_types.count() == 7); // Cả != cả
    try std.testing.expect(text.syllable_types.get("nha|f").?.count == 2);
    try std.testing.expect(text.syllow00_types.count() == 6); // Cả => cả
    try std.testing.expect(text.syllow00_types.get("ca|").?.count == 2);
    try std.testing.expect(text.nonalpha_types.count() == 0); // cauz all is alphabet
}
