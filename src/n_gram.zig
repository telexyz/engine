// REF https://kheafield.com/code/kenlm

const std = @import("std");

const Text = @import("./text_data_struct.zig").Text;
const syllable_data_structs = @import("./syllable_data_structs.zig");
const Syllable = syllable_data_structs.Syllable;
const BLANK: Syllable.UniqueId = 0;

const Gram = packed struct {
    s0: Syllable.UniqueId = BLANK,
    s1: Syllable.UniqueId = BLANK,
    s2: Syllable.UniqueId = BLANK,
    s3: Syllable.UniqueId = BLANK,
    s4: Syllable.UniqueId = BLANK,

    fn isFiveGram(self: Gram) bool {
        return self.s0 != BLANK and self.s1 != BLANK and self.s2 != BLANK and
            self.s3 != BLANK and self.s4 != BLANK;
    }
    fn isFourGram(self: Gram) bool {
        return self.s1 != BLANK and self.s2 != BLANK and
            self.s3 != BLANK and self.s4 != BLANK;
    }

    fn isTriGram(self: Gram) bool {
        return self.s2 != BLANK and
            self.s3 != BLANK and self.s4 != BLANK;
    }

    fn isBiGram(self: Gram) bool {
        return true and
            self.s3 != BLANK and self.s4 != BLANK;
    }

    pub fn printToBuffUtf8(self: Gram, buffer: []u8) []const u8 {
        var n: usize = 0;
        var buff: []u8 = undefined;

        if (self.s0 != BLANK) {
            buff = buffer[n..];
            n += Syllable.newFromId(self.s0).printBuffUtf8(buff).len;
            buffer[n] = 32;
            n += 1;
        }

        if (self.s1 != BLANK) {
            buff = buffer[n..];
            n += Syllable.newFromId(self.s1).printBuffUtf8(buff).len;
            buffer[n] = 32;
            n += 1;
        }

        if (self.s2 != BLANK) {
            buff = buffer[n..];
            n += Syllable.newFromId(self.s2).printBuffUtf8(buff).len;
            buffer[n] = 32;
            n += 1;
        }

        buff = buffer[n..];
        n += Syllable.newFromId(self.s3).printBuffUtf8(buff).len;

        buffer[n] = 32;
        n += 1;

        buff = buffer[n..];
        n += Syllable.newFromId(self.s4).printBuffUtf8(buff).len;

        return buffer[0..n];
    }
};

const GramCount = std.AutoHashMap(Gram, u32);

pub const NGram = struct {
    bi_gram_counts: GramCount = undefined,
    tri_gram_counts: GramCount = undefined,
    four_gram_counts: GramCount = undefined,
    five_gram_counts: GramCount = undefined,

    arena: std.heap.ArenaAllocator = undefined,
    allocator: *std.mem.Allocator = undefined,

    pub const MIN_COUNT = 3;

    pub fn init(self: *NGram, init_allocator: *std.mem.Allocator) void {
        self.arena = std.heap.ArenaAllocator.init(init_allocator);
        self.allocator = &self.arena.allocator;

        self.bi_gram_counts = GramCount.init(self.allocator);
        self.tri_gram_counts = GramCount.init(self.allocator);
        self.four_gram_counts = GramCount.init(self.allocator);
        self.five_gram_counts = GramCount.init(self.allocator);
    }

    pub fn deinit(self: *NGram) void {
        self.arena.deinit();
    }

    pub const Error = error{
        TextNotFinalized,
    };
    pub fn parse(self: *NGram, text: Text) !void {
        if (!text.tokens_number_finalized) return Error.TextNotFinalized;
        _ = self;

        var gram: Gram = .{};
        var n = text.tokens_number;
        var i: usize = 0;
        var prev_s1: Syllable.UniqueId = BLANK;
        var prev_s2: Syllable.UniqueId = BLANK;

        while (i < n) : (i += 1) {
            //
            const is_syllable = text.tokens_attrs[i].isSyllable();

            gram.s0 = prev_s1; // s0 := s1
            gram.s1 = prev_s2; // s1 := s2
            gram.s2 = gram.s3;
            gram.s3 = gram.s4;
            gram.s4 = if (is_syllable) text.syllable_ids[i] else BLANK;

            if (gram.isFiveGram()) {
                const gop = try self.five_gram_counts.getOrPutValue(gram, 0);
                gop.value_ptr.* += 1;
            }

            gram.s0 = BLANK;
            if (gram.isFourGram()) {
                const gop = try self.four_gram_counts.getOrPutValue(gram, 0);
                gop.value_ptr.* += 1;
            }

            prev_s1 = gram.s1;
            gram.s1 = BLANK;
            if (gram.isTriGram()) {
                const gop = try self.tri_gram_counts.getOrPutValue(gram, 0);
                gop.value_ptr.* += 1;
            }

            prev_s2 = gram.s2;
            gram.s2 = BLANK;
            if (gram.isBiGram()) {
                const gop = try self.bi_gram_counts.getOrPutValue(gram, 0);
                gop.value_ptr.* += 1;
            }
        }
    }
};

const GramInfo = struct {
    value: Gram,
    count: u32,
};

fn order_by_count_desc(context: void, a: GramInfo, b: GramInfo) bool {
    _ = context;
    return a.count > b.count;
}

pub fn writeGramCounts(grams: GramCount, filename: []const u8) !void {
    var buffer: [13 * 5]u8 = undefined;
    const buff = buffer[0..];

    // Init list
    var grams_list = try std.ArrayList(GramInfo).initCapacity(std.heap.page_allocator, grams.count());
    defer grams_list.deinit();

    // Add items
    var it = grams.iterator();
    while (it.next()) |kv| {
        if (kv.value_ptr.* < NGram.MIN_COUNT) continue;
        try grams_list.append(.{
            .value = kv.key_ptr.*,
            .count = kv.value_ptr.*,
        });
    }

    // Sort by count desc
    std.sort.sort(GramInfo, grams_list.items, {}, order_by_count_desc);

    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    var wrt = std.io.bufferedWriter(file.writer());

    for (grams_list.items) |gram| {
        try wrt.writer().print("{d} {s}\n", .{
            gram.count,
            gram.value.printToBuffUtf8(buff),
        });
    }

    try wrt.flush();
}

const text_utils = @import("./text_utils.zig");

test "ngram" {
    var gram: NGram = .{};
    gram.init(std.testing.allocator);
    defer gram.deinit();

    var text = Text{
        .init_allocator = std.testing.allocator,
    };
    try text.initFromInputBytes("Cả nhà đơi thử nghiệm nhé , cả nhà ! TAQs");
    defer text.deinit();

    var it = std.mem.tokenize(text.input_bytes, " ");
    var attrs: Text.TokenAttributes = .{
        .category = .alphabet,
        .surrounded_by_spaces = .both,
    };
    while (it.next()) |tkn| {
        try text.recordToken(tkn, attrs);
    }

    text.tokens_number_finalized = true;
    text_utils.parseTokens(&text);
    try gram.parse(text);
}
