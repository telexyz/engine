const std = @import("std");
const File = std.fs.File;

const syllable_data_structs = @import("./syllable_data_structs.zig");
const Syllable = syllable_data_structs.Syllable;

const telex_char_stream = @import("./telex_char_stream.zig");
const U2ACharStream = telex_char_stream.Utf8ToAsciiTelexCharStream;

pub const Text = struct {
    // Keep origin data as-much-as-possible
    keep_origin_amap: bool = true,
    convert_mode: u8 = 1, // dense

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

    // out-of-size tokens
    alphabet_too_long_tokens: std.ArrayList([]const u8) = undefined,
    nonalpha_too_long_tokens: std.ArrayList([]const u8) = undefined,

    // A token can have multiple transforms:
    // For example ascii_transforms[i] is the ascii-telex transformation of tokens[i]
    // ascii_transforms should be used only if token is a VN syllable for sure,
    // other use-case should be considered carefully since we may loose
    // the original form of the input. For example:
    // "vớiiiii...." can be converted to ascii-telex "vowisiiii....",
    // but it not looked right for me. I think it we should keep original form.
    // Same tokens counted to type, we will save transform in TypeInfo

    // Data buffer for syllable_types
    syllable_bytes: []u8 = undefined,
    syllable_bytes_len: usize = 0,

    // Same tokens are counted as a type
    // Listing tytes along with its frequence will reveal intersting information

    // Use data of input_bytes, pointed by tokens[i]
    syllabet_types: std.StringHashMap(TypeInfo) = undefined,
    alphabet_types: std.StringHashMap(TypeInfo) = undefined,
    nonalpha_types: std.StringHashMap(u32) = undefined,

    // Use data of transformed_bytes, pointed by transforms[i]
    syllable_types: std.StringHashMap(TypeInfo) = undefined, // syllable.toLower-mark-tone
    syllow0t_types: std.StringHashMap(TypeInfo) = undefined, // = syllow0t

    // Data buffer for syllow0t_types
    syllow0t_bytes: []u8 = undefined,
    syllow0t_bytes_len: usize = 0,

    // Start the text with empty tokens list, hence tokens_number = 0
    tokens_number: usize = 0,
    parsed_input_bytes: usize = 0,
    parsed_tokens_number: usize = 0,
    tokens_number_finalized: bool = false,

    // The we split input bytes into a list of tokens
    // A toke is a slice of []const u8, that point to the original input bytes
    // (normally input byte are readed from a text file, corpus.txt for example)
    // Each tokens[i] slice will point to the original input_bytes

    // Try to predict maxium number of token to alloc mememory in advance
    estimated_tokens_number: usize = undefined,
    recored_byte_addr: usize = undefined, // used to calculate TokenInfo#skip
    tokens_infos: std.ArrayList(TokenInfo) = undefined,

    const TokenSkipType = u16;
    const TOKEN_MAX_SKIP = 0xffff;

    const TokenLenType = u16;
    const TOKEN_MAX_LEN = 0xffff;

    pub const TokenInfo = struct { //   Total  7-bytes
        skip: TokenSkipType = undefined, //    2-bytes
        len: TokenLenType = undefined, //      2-bytes
        syllable_id: Syllable.UniqueId = 0, // 2-bytes
        attrs: TokenAttributes = undefined, // 1-byte
    };

    pub const MAX_TOKEN_LEN = 20;
    const MAX_INPUT_FILE_SIZE = 1336 * 1024 * 1024; // 1.3Gb
    const TEXT_DICT_FILE_SIZE = 1024 * 1024; // 1Mb
    const AVG_BYTES_PER_TOKEN = 3;
    const BUFF_SIZE = 256; // incase input is small, estimated not correct

    pub const TypeInfo = struct {
        count: u32 = 0,
        transform: []const u8 = undefined,
        category: TokenCategory = ._none,
        syllable_id: Syllable.UniqueId = 0,

        pub fn isSyllable(self: TypeInfo) bool {
            return self.syllable_id > 0;
            // return self.category == .syllmark or self.category == .syllable;
        }

        pub fn haveMarkTone(self: TypeInfo) bool {
            return self.category == .syllmark or self.category == .alphmark;
        }
    };

    // A token can have multiple atributes:
    // Each attribute is re-presented by an enum
    // The final encoded attribute is re-presented by a struct
    pub const TokenAttributes = packed struct {
        surrounded_by_spaces: TokenSurroundedBySpaces,
        category: TokenCategory,

        pub fn spaceAfter(self: TokenAttributes) bool {
            return self.surrounded_by_spaces == .right or
                self.surrounded_by_spaces == .both;
        }

        pub fn isSyllable(self: TokenAttributes) bool {
            return self.category == .syllmark or self.category == .syllable;
        }

        pub fn haveMarkTone(self: TypeInfo) bool {
            return self.category == .syllmark or self.category == .alphmark;
        }

        pub fn toByte(self: TokenAttributes) u8 {
            const byte = @bitCast(u8, self);
            if (byte < 12) return byte + 1;
            return byte;
        }
        pub fn newFromByte(byte: u8) TokenAttributes {
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
        alphabet = 5, //  + 2-bits  => 20,21,22,23     => \x14\x15\x16\x17
        syllmark = 6, //  + 2-bits  => 24,25,26,27     => \x18\x19\x1a\x1b
        syllable = 7, //  + 2-bits  => 28,29,30,31     => \x1c\x1d\x1e\x1f
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
        self.initAllocatorIfNeeded();
        var input_file = try std.fs.cwd().openFile(input_filename, .{ .read = true });
        defer input_file.close();
        var input_bytes = try input_file.reader().readAllAlloc(self.allocator, MAX_INPUT_FILE_SIZE);
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
        self.recored_byte_addr = @ptrToInt(input_bytes.ptr);

        const input_bytes_size = self.input_bytes.len;
        self.estimated_tokens_number = input_bytes_size / AVG_BYTES_PER_TOKEN + BUFF_SIZE;

        // Init tokens infos list
        self.tokens_infos = try std.ArrayList(TokenInfo).initCapacity(
            self.allocator,
            self.estimated_tokens_number,
        );

        // Init types count
        self.syllabet_types = std.StringHashMap(TypeInfo).init(self.allocator);
        self.alphabet_types = std.StringHashMap(TypeInfo).init(self.allocator);
        self.nonalpha_types = std.StringHashMap(u32).init(self.allocator);
        self.syllable_types = std.StringHashMap(TypeInfo).init(self.allocator);

        self.alphabet_too_long_tokens = std.ArrayList([]const u8).init(self.allocator);
        self.nonalpha_too_long_tokens = std.ArrayList([]const u8).init(self.allocator);

        // Init transformed_bytes, each token may have an additional byte at the
        // begining to store it's attribute so we need more memory than input_bytes

        // Init syllable...
        self.syllable_bytes = try self.allocator.alloc(u8, 3 * TEXT_DICT_FILE_SIZE);
        self.syllable_bytes_len = 0;

        // Init syllower...
        self.syllow0t_types = std.StringHashMap(TypeInfo).init(self.allocator);
        self.syllow0t_bytes = try self.allocator.alloc(u8, TEXT_DICT_FILE_SIZE);
        self.syllow0t_bytes_len = 0;

        // Start empty token list and empty transfomed bytes
        self.tokens_number = 0;
    }

    pub fn free_input_bytes(self: *Text) void {
        self.allocator.free(self.input_bytes);
    }
    pub fn deinit(self: *Text) void {
        // Since we use ArenaAllocator, simply deinit arena itself to
        // free all allocated memories
        self.arena.deinit();
    }
    pub fn getToken(self: Text, n: usize) []const u8 {
        if (n < self.tokens_number) {
            var i: usize = 0;
            var curr: usize = 0;
            var next: usize = 0;
            while (i <= n) : (i += 1) {
                const token_info = self.tokens_infos.items[i];
                curr = next + token_info.skip;
                next = curr + token_info.len;
            }
            return self.input_bytes[curr..next];
        } else {
            std.debug.print("!!! n: {} is bigger than tokens_number !!!", .{n});
            unreachable;
        }
    }
    pub fn recordToken(self: *Text, token: []const u8, attrs: TokenAttributes) !void {
        const tkn_addr = @ptrToInt(token.ptr);
        const skip = tkn_addr - self.recored_byte_addr;
        self.recored_byte_addr = tkn_addr + token.len;

        // var token_info = TokenInfo{ .attrs = attrs };
        // if (skip < TOKEN_MAX_SKIP and token.len < TOKEN_MAX_LEN) {
        //     token_info.skip = @intCast(TokenSkipType, skip);
        //     token_info.len = @intCast(TokenLenType, token.len);
        // } else {
        //     std.debug.print("\n !! OUT OF skip {d} OR len {d} !!", .{ skip, token.len });
        //     unreachable;
        // }
        // token_info.skip = @intCast(TokenSkipType, skip);
        // token_info.len = @intCast(TokenLenType, token.len);
        // try self.tokens_infos.append(token_info);

        try self.tokens_infos.append(.{
            .attrs = attrs,
            .skip = @intCast(TokenSkipType, skip),
            .len = @intCast(TokenLenType, token.len),
        });

        if (token.len <= MAX_TOKEN_LEN) {
            if (attrs.category == .nonalpha) {
                const gop = try self.nonalpha_types.getOrPutValue(token, 0);
                gop.value_ptr.* += 1;
            } else if (token.len <= U2ACharStream.MAX_LEN) {
                // Log token type that can be syllable
                const gop = try self.syllabet_types.getOrPutValue(token, Text.TypeInfo{
                    .count = 0,
                    .category = ._none,
                });
                gop.value_ptr.count += 1;
            }
        } else {
            // Log too long tokens
            if (attrs.category == .nonalpha)
                try self.nonalpha_too_long_tokens.append(token)
            else
                try self.alphabet_too_long_tokens.append(token);
        }
        // increare tokens_number only when everything is finalized
        self.tokens_number += 1;
    }

    pub fn processSyllabetTypes(self: *Text) !void {
        if (!self.tokens_number_finalized) return;

        var it = self.syllabet_types.iterator();
        while (it.next()) |kv| {
            if (kv.value_ptr.isSyllable()) {
                // std.debug.print("\n{s} => {}", .{kv.value_ptr.transform, kv.value_ptr});
                try self.countSyllableAndSyllow0t(kv.value_ptr.transform, kv.value_ptr);
            } else {
                // std.debug.print("\n{s} => {}", .{ kv.value_ptr, kv.value_ptr });
                _ = try self.alphabet_types.put(kv.key_ptr.*, kv.value_ptr.*);
            }
        }
    }

    pub fn countSyllableAndSyllow0t(self: *Text, syllable: []const u8, type_info: *const Text.TypeInfo) !void {
        // Record and count syllable
        const gop1 = try self.syllable_types.getOrPutValue(syllable, TypeInfo{ .category = type_info.category });
        gop1.value_ptr.count += type_info.count;

        // Convert syllable to syllow0t
        var i: u8 = if (syllable[0] == '^') 1 else 0;
        if (i == 1 and (syllable[1] == '^' or syllable[1] == 32)) i = 2;
        if (i == 2 and syllable[2] == 32) i = 3;

        var n = syllable.len - 1;
        n = switch (syllable[n]) {
            's', 'f', 'r', 'x', 'j' => n, // remove tone "[sfrxj]"
            else => n + 1,
        };

        var next = self.syllow0t_bytes_len;
        while (i < n) : (i += 1) {
            self.syllow0t_bytes[next] = syllable[i];
            next += 1;
        }

        const syllow0t = self.syllow0t_bytes[self.syllow0t_bytes_len..next];
        self.syllow0t_bytes_len = next;

        const gop2 = try self.syllow0t_types.getOrPutValue(syllow0t, TypeInfo{ .category = type_info.category });
        gop2.value_ptr.count += type_info.count;
    }
};

const text_utils = @import("./text_utils.zig");

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
    var it = std.mem.tokenize(text.input_bytes, " ");
    var token = it.next();
    var attrs: Text.TokenAttributes = .{
        .category = .alphabet,
        .surrounded_by_spaces = .both,
    };
    try text.recordToken(token.?, attrs);
    try std.testing.expect(text.tokens_number == 1);
    try std.testing.expectEqualStrings(text.getToken(0), "Cả");

    try text.recordToken(it.next().?, attrs);
    try text.recordToken(it.next().?, attrs);

    const thread = try std.Thread.spawn(.{}, text_utils.parseTokens, .{&text});
    while (it.next()) |tkn| {
        try text.recordToken(tkn, attrs);
    }
    text.tokens_number_finalized = true;
    thread.join();
    text_utils.parseTokens(&text);
    try text.processSyllabetTypes();

    try std.testing.expect(text.tokens_number == 12);
    try std.testing.expectEqualStrings(text.getToken(9), "nhà");
    try std.testing.expect(text.alphabet_types.get("!").?.count == 1);
    try std.testing.expect(text.alphabet_types.get(",").?.count == 2);
    try std.testing.expect(text.alphabet_types.get("TAQs").?.count == 1);
    try std.testing.expect(text.alphabet_types.get("xxx") == null);
    try std.testing.expect(text.alphabet_types.count() == 3);

    //  1s 2s  3s  1a 4s  5s     6s  1a 1s 2s  2a 3a
    // "Cả nhà đơi ,  thử nghiệm nhé ,  cả nhà !  TAQs"
    // std.debug.print("\n{}\n", .{text.syllable_types.get("nha|f").?.count});
    // std.debug.print("\n{}\n\n", .{text.syllow0t_types.get("ca|").?.count});
    try std.testing.expect(text.syllable_types.count() == 7); // Cả != cả
    try std.testing.expect(text.syllable_types.get("nha|f").?.count == 2);
    try std.testing.expect(text.syllow0t_types.count() == 6); // Cả => cả
    try std.testing.expect(text.syllow0t_types.get("ca|").?.count == 2);
    try std.testing.expect(text.nonalpha_types.count() == 0); // cauz all is alphabet
}
