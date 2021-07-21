// https://kheafield.com/code/kenlm
// http://www.cs.jhu.edu/~phi

const std = @import("std");

const syllable_data_structs = @import("./syllable_data_structs.zig");
const Syllable = syllable_data_structs.Syllable;
const Text = @import("./text_data_struct.zig").Text;

const BiTriGram = packed struct {
    const BLANK: Syllable.UniqueId = 0;

    s0: Syllable.UniqueId = BLANK,
    s1: Syllable.UniqueId = BLANK,
    s2: Syllable.UniqueId = BLANK,

    fn isTriSyllables(self: BiTriGram) bool {
        return self.s0 != BLANK and self.s1 != BLANK and self.s2 != BLANK;
    }

    fn isBiSyllables(self: BiTriGram) bool {
        return self.s1 != BLANK and self.s2 != BLANK;
    }

    pub fn printToBuffUtf8(self: BiTriGram, buffer: []u8) []const u8 {
        var n: usize = 0;
        var buff: []u8 = buffer;

        if (self.s0 != BLANK) {
            n += Syllable.newFromId(self.s0).printBuffUtf8(buff).len;
            buffer[n] = 32;
            n += 1;
        }

        buff = buffer[n..];
        n += Syllable.newFromId(self.s1).printBuffUtf8(buff).len;

        buffer[n] = 32;
        n += 1;

        buff = buffer[n..];
        n += Syllable.newFromId(self.s2).printBuffUtf8(buff).len;

        return buffer[0..n];
    }
};

const BiTriGramCount = std.AutoHashMap(BiTriGram, u32);

pub const NGram = struct {
    bi_gram_counts: BiTriGramCount = undefined,
    tri_gram_counts: BiTriGramCount = undefined,

    pub const MIN_COUNT = 0;

    pub fn init(self: *NGram, allocator: *std.mem.Allocator) void {
        self.bi_gram_counts = BiTriGramCount.init(allocator);
        self.tri_gram_counts = BiTriGramCount.init(allocator);
    }

    pub fn deinit(self: *NGram) void {
        self.bi_gram_counts.deinit();
        self.tri_gram_counts.deinit();
    }

    pub const Error = error{
        TextNotFinalized,
    };
    pub fn parse(self: *NGram, text: Text) !void {
        if (!text.tokens_number_finalized) return Error.TextNotFinalized;
        _ = self;

        // var buffer: [16 * 3]u8 = undefined;
        // const buff = buffer[0..];

        var bi_tri_gram: BiTriGram = .{};
        var n = text.tokens_number;
        var i: usize = 0;

        while (i < n) : (i += 1) {
            //
            const is_syllable = text.tokens_attrs[i].isSyllable();

            // if (is_syllable) std.debug.print("{s} ", .{text.tokens[i]}) else std.debug.print("\n", .{}); //OK

            bi_tri_gram.s0 = bi_tri_gram.s1;
            bi_tri_gram.s1 = bi_tri_gram.s2;
            bi_tri_gram.s2 = if (is_syllable) text.syllable_ids[i] else BiTriGram.BLANK;

            if (bi_tri_gram.isTriSyllables()) {
                // std.debug.print(" |{s}| ", .{bi_tri_gram.printToBuffUtf8(buff)}); //OK
                const gop = try self.tri_gram_counts.getOrPutValue(bi_tri_gram, 0);
                gop.value_ptr.* += 1;
            }

            bi_tri_gram.s0 = BiTriGram.BLANK;
            if (bi_tri_gram.isBiSyllables()) {
                // std.debug.print(" |{s}| ", .{bi_tri_gram.printToBuffUtf8(buff)});//OK
                const gop = try self.bi_gram_counts.getOrPutValue(bi_tri_gram, 0);
                gop.value_ptr.* += 1;
            }
        }
    }
};

const GramInfo = struct {
    value: BiTriGram,
    count: u32,
};

fn order_by_count_desc(context: void, a: GramInfo, b: GramInfo) bool {
    _ = context;
    return a.count > b.count;
}

pub fn writeGramCounts(grams: BiTriGramCount, filename: []const u8) !void {
    var buffer: [16 * 3]u8 = undefined;
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
        try wrt.writer().print("{d} {s}\n", .{ gram.count, gram.value.printToBuffUtf8(buff) });
    }
    try wrt.flush();
}

const text_utils = @import("./text_utils.zig");

test "ngram" {
    var gram: NGram = .{};
    gram.init(std.heap.page_allocator);
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
