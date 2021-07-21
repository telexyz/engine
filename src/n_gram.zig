// https://kheafield.com/code/kenlm
// http://www.cs.jhu.edu/~phi

const std = @import("std");

const syllable_data_structs = @import("./syllable_data_structs.zig");
const Syllable = syllable_data_structs.Syllable;
const Text = @import("./text_data_struct.zig").Text;

const Gram = packed struct {
    const BLANK: Syllable.UniqueId = 0;

    s0: Syllable.UniqueId = BLANK,
    s1: Syllable.UniqueId = BLANK,
    s2: Syllable.UniqueId = BLANK,
    s3: Syllable.UniqueId = BLANK,

    fn isFourGram(self: Gram) bool {
        return self.s0 != BLANK and self.s1 != BLANK and
            self.s2 != BLANK and self.s3 != BLANK;
    }

    fn isTriGram(self: Gram) bool {
        return self.s1 != BLANK and
            self.s2 != BLANK and self.s3 != BLANK;
    }

    fn isBiGram(self: Gram) bool {
        return true and
            self.s2 != BLANK and self.s3 != BLANK;
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

        buff = buffer[n..];
        n += Syllable.newFromId(self.s2).printBuffUtf8(buff).len;

        buffer[n] = 32;
        n += 1;

        buff = buffer[n..];
        n += Syllable.newFromId(self.s3).printBuffUtf8(buff).len;

        return buffer[0..n];
    }
};

const GramCount = std.AutoHashMap(Gram, u32);

pub const NGram = struct {
    bi_gram_counts: GramCount = undefined,
    tri_gram_counts: GramCount = undefined,
    four_gram_counts: GramCount = undefined,

    pub const MIN_COUNT = 0;

    pub fn init(self: *NGram, allocator: *std.mem.Allocator) void {
        self.bi_gram_counts = GramCount.init(allocator);
        self.tri_gram_counts = GramCount.init(allocator);
        self.four_gram_counts = GramCount.init(allocator);
    }

    pub fn deinit(self: *NGram) void {
        self.bi_gram_counts.deinit();
        self.tri_gram_counts.deinit();
        self.four_gram_counts.deinit();
    }

    pub const Error = error{
        TextNotFinalized,
    };
    pub fn parse(self: *NGram, text: Text) !void {
        if (!text.tokens_number_finalized) return Error.TextNotFinalized;
        _ = self;

        // var buffer: [18 * 4]u8 = undefined;
        // const buff = buffer[0..];

        var gram: Gram = .{};
        var n = text.tokens_number;
        var i: usize = 0;

        while (i < n) : (i += 1) {
            //
            const is_syllable = text.tokens_attrs[i].isSyllable();

            // if (is_syllable) std.debug.print("{s} ", .{text.tokens[i]}) else std.debug.print("\n", .{}); //OK

            gram.s1 = gram.s2;
            gram.s2 = gram.s3;
            gram.s3 = if (is_syllable) text.syllable_ids[i] else Gram.BLANK;

            if (gram.isFourGram()) {
                // std.debug.print(" |{s}| ", .{gram.printToBuffUtf8(buff)}); //OK
                const gop = try self.four_gram_counts.getOrPutValue(gram, 0);
                gop.value_ptr.* += 1;
            }

            gram.s0 = Gram.BLANK;
            if (gram.isTriGram()) {
                // std.debug.print(" |{s}| ", .{gram.printToBuffUtf8(buff)}); //OK
                const gop = try self.tri_gram_counts.getOrPutValue(gram, 0);
                gop.value_ptr.* += 1;
            }

            const temp = gram.s1;
            gram.s1 = Gram.BLANK;
            if (gram.isBiGram()) {
                // std.debug.print(" |{s}| ", .{gram.printToBuffUtf8(buff)});//OK
                const gop = try self.bi_gram_counts.getOrPutValue(gram, 0);
                gop.value_ptr.* += 1;
            }
            gram.s0 = temp; // s0 := s1
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
    var buffer: [18 * 4]u8 = undefined;
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
