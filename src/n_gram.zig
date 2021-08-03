// REF https://kheafield.com/code/kenlm

const std = @import("std");
const Text = @import("./text_data_struct.zig").Text;
const Syllable = @import("./syllable_data_structs.zig").Syllable;
const BLANK: Syllable.UniqueId = 0;

const FourGram = packed struct {
    s0: Syllable.UniqueId = BLANK,
    s1: Syllable.UniqueId = BLANK,
    s2: Syllable.UniqueId = BLANK,
    s3: Syllable.UniqueId = BLANK,

    pub fn printBuffUtf8(self: FourGram, buff: []u8) []const u8 {
        var n = Syllable.newFromId(self.s0).printBuffUtf8(buff).len;
        buff[n] = 32;
        n += 1;
        n += Syllable.newFromId(self.s1).printBuffUtf8(buff[n..]).len;

        if (self.s2 != BLANK) {
            buff[n] = 32;
            n += 1;
            n += Syllable.newFromId(self.s2).printBuffUtf8(buff[n..]).len;
        }

        if (self.s3 != BLANK) {
            buff[n] = 32;
            n += 1;
            n += Syllable.newFromId(self.s3).printBuffUtf8(buff[n..]).len;
        }
        return buff[0..n];
    }
};

const TriGram = packed struct {
    s0: Syllable.UniqueId,
    s1: Syllable.UniqueId,
    s2: Syllable.UniqueId,
};

const BiGram = packed struct {
    s0: Syllable.UniqueId,
    s1: Syllable.UniqueId,
};

pub const NGram = struct {
    bi_gram_counts: std.AutoHashMap(BiGram, u32) = undefined,
    tri_gram_counts: std.AutoHashMap(TriGram, u32) = undefined,
    four_gram_counts: std.AutoHashMap(FourGram, u32) = undefined,

    arena: std.heap.ArenaAllocator = undefined,

    pub const MIN_COUNT = 3;

    pub fn init(self: *NGram, init_allocator: *std.mem.Allocator) void {
        self.arena = std.heap.ArenaAllocator.init(init_allocator);
        self.bi_gram_counts = std.AutoHashMap(BiGram, u32).init(&self.arena.allocator);
        self.tri_gram_counts = std.AutoHashMap(TriGram, u32).init(&self.arena.allocator);
        self.four_gram_counts = std.AutoHashMap(FourGram, u32).init(&self.arena.allocator);
    }

    pub fn deinit(self: *NGram) void {
        self.arena.deinit();
    }

    pub const Error = error{
        TextNotFinalized,
    };

    pub fn parseAndWriteBiGram(self: *NGram, text: Text, filename: []const u8) !void {
        if (!text.tokens_number_finalized) return Error.TextNotFinalized;
        var gram = BiGram{ .s0 = BLANK, .s1 = BLANK };
        var n = text.tokens_number;
        var i: usize = 0;
        while (i < n) : (i += 1) {
            gram.s0 = gram.s1;
            gram.s1 = if (text.tokens_attrs[i].isSyllable()) text.syllable_ids[i] else BLANK;
            if (gram.s0 == BLANK or gram.s1 == BLANK) continue;
            const gop = try self.bi_gram_counts.getOrPutValue(gram, 0);
            gop.value_ptr.* += 1;
        }
        try writeGramCounts(self.bi_gram_counts, filename);
    }

    pub fn parseAndWriteTriGram(self: *NGram, text: Text, filename: []const u8) void {
        var gram = TriGram{ .s0 = BLANK, .s1 = BLANK, .s2 = BLANK };
        var n = text.tokens_number;
        var i: usize = 0;
        while (i < n) : (i += 1) {
            gram.s0 = gram.s1;
            gram.s1 = gram.s2;
            gram.s2 = if (text.tokens_attrs[i].isSyllable()) text.syllable_ids[i] else BLANK;
            if (gram.s0 == BLANK or gram.s1 == BLANK or gram.s2 == BLANK) continue;
            const gop = self.tri_gram_counts.getOrPutValue(gram, 0) catch unreachable;
            gop.value_ptr.* += 1;
        }
        writeGramCounts(self.tri_gram_counts, filename) catch unreachable;
    }

    pub fn parseAndWriteFourGram(self: *NGram, text: Text, filename: []const u8) void {
        var gram: FourGram = .{};
        var n = text.tokens_number;
        var i: usize = 0;
        while (i < n) : (i += 1) {
            gram.s0 = gram.s1;
            gram.s1 = gram.s2;
            gram.s2 = gram.s3;
            gram.s3 = if (text.tokens_attrs[i].isSyllable()) text.syllable_ids[i] else BLANK;
            if (gram.s0 == BLANK or gram.s1 == BLANK) continue;
            if (gram.s2 == BLANK or gram.s3 == BLANK) continue;
            const gop = self.four_gram_counts.getOrPutValue(gram, 0) catch unreachable;
            gop.value_ptr.* += 1;
        }
        writeGramCounts(self.four_gram_counts, filename) catch unreachable;
    }

    pub fn parse(self: *NGram, text: Text) !void {
        if (!text.tokens_number_finalized) return Error.TextNotFinalized;

        var gram: FourGram = .{};
        var n = text.tokens_number;
        var i: usize = 0;

        const attrs = text.tokens_attrs;
        const syids = text.syllable_ids;

        while (i < n) : (i += 1) {
            gram.s0 = gram.s1;
            gram.s1 = gram.s2;
            gram.s2 = gram.s3;
            gram.s3 = if (attrs[i].isSyllable()) syids[i] else BLANK;

            if (gram.s2 != BLANK and gram.s3 != BLANK) { // bi-gram
                const bigram = BiGram{ .s0 = gram.s2, .s1 = gram.s3 };
                const gop2 = try self.bi_gram_counts.getOrPutValue(bigram, 0);
                gop2.value_ptr.* += 1;

                if (gram.s1 != BLANK) { // tri-gram
                    const trigram = TriGram{ .s0 = gram.s1, .s1 = gram.s2, .s2 = gram.s3 };
                    const gop3 = try self.tri_gram_counts.getOrPutValue(trigram, 0);
                    gop3.value_ptr.* += 1;

                    if (gram.s0 != BLANK) { // fourth-gram
                        const gop4 = try self.four_gram_counts.getOrPutValue(gram, 0);
                        gop4.value_ptr.* += 1;
                    }
                } // tri-gram
            }
        } // while
    }
};

const GramInfo = struct {
    value: FourGram,
    count: u32,
};

fn order_by_count_desc(context: void, a: GramInfo, b: GramInfo) bool {
    _ = context;
    return a.count > b.count;
}

pub fn writeGramCounts(grams: anytype, filename: []const u8) !void {
    var buffer: [13 * 5]u8 = undefined;
    const buff = buffer[0..];

    var grams_list = try std.ArrayList(GramInfo).initCapacity(
        std.heap.page_allocator,
        grams.count(),
    );
    defer grams_list.deinit();

    // Add items
    var it = grams.iterator();
    while (it.next()) |kv| {
        const gram = kv.key_ptr.*;
        const count = kv.value_ptr.*;

        if (count < NGram.MIN_COUNT) continue;

        switch (@TypeOf(grams)) {
            std.AutoHashMap(BiGram, u32) => {
                try grams_list.append(.{
                    .value = FourGram{ .s0 = gram.s0, .s1 = gram.s1 },
                    .count = count,
                });
            },
            std.AutoHashMap(TriGram, u32) => {
                try grams_list.append(.{
                    .value = FourGram{ .s0 = gram.s0, .s1 = gram.s1, .s2 = gram.s2 },
                    .count = count,
                });
            },
            else => {
                try grams_list.append(.{
                    .value = gram,
                    .count = count,
                });
            },
        } // switch
    } // while

    // Sort by count desc
    std.sort.sort(GramInfo, grams_list.items, {}, order_by_count_desc);

    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    var wrt = std.io.bufferedWriter(file.writer());

    for (grams_list.items) |gram| {
        try wrt.writer().print("{d} {s}\n", .{
            gram.count,
            gram.value.printBuffUtf8(buff),
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
    try text.initFromInputBytes("Cả nhà nhà nhà nhà nhà nhà nhà nhà nhà đơi thử nghiệm nhé , cả nhà ! TAQs cả nhà");
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

    try gram.parseAndWriteBiGram(text, "data/temp2.txt");
    gram.parseAndWriteTriGram(text, "data/temp3.txt");
    gram.parseAndWriteFourGram(text, "data/temp4.txt");

    try gram.parse(text);
    try writeGramCounts(gram.bi_gram_counts, "data/temp.txt");
}
