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

    pub const MIN_COUNT = 9;

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

    const PAD = "                        ";
    pub fn parseAndWriteFourGram(self: *NGram, text: Text, filename: []const u8) void {
        // Record progress
        const ten_percents = text.tokens_number / 10;
        var percents_threshold = ten_percents;
        var percents: u8 = 0;

        var gram: FourGram = .{};
        var i: usize = 0;

        while (i < text.tokens_number) : (i += 1) {
            // Show progress
            if (i >= percents_threshold) {
                percents += 10;
                std.debug.print("Parsing four-gram {d}%\n", .{percents});
                percents_threshold += ten_percents;
            }

            const token_info = text.tokens_infos[i];

            gram.s0 = gram.s1;
            gram.s1 = gram.s2;
            gram.s2 = gram.s3;
            gram.s3 = token_info.syllable_id;

            if (gram.s0 == BLANK or gram.s1 == BLANK) continue;
            if (gram.s2 == BLANK or gram.s3 == BLANK) continue;

            const gop = self.four_gram_counts.getOrPutValue(gram, 0) catch {
                std.debug.print("!!! CANNOT PUT VALUE TO four_gram_counts !!!", .{});
                unreachable;
            };
            gop.value_ptr.* += 1;
        }
        writeGramCounts(self.four_gram_counts, filename) catch {
            std.debug.print("!!! CANOT WRITE four_gram_counts to {s} !!!", .{filename});
            unreachable;
        };
    }

    pub fn parseAndWriteBiTriGram(
        self: *NGram,
        text: Text,
        bi_filename: []const u8,
        tri_filename: []const u8,
    ) void {
        // Record progress
        const ten_percents = text.tokens_number / 10;
        var percents_threshold = ten_percents;
        var percents: u8 = 0;
        var gram: TriGram = .{ .s0 = BLANK, .s1 = BLANK, .s2 = BLANK };

        var i: usize = 0;
        while (i < text.tokens_number) : (i += 1) {
            // Show progress
            if (i >= percents_threshold) {
                percents += 10;
                std.debug.print("{s}{d}% Parsing bi,tri-gram\n", .{ PAD, percents });
                percents_threshold += ten_percents;
            }

            const token_info = text.tokens_infos[i];
            gram.s0 = gram.s1;
            gram.s1 = gram.s2;
            gram.s2 = token_info.syllable_id;

            if (gram.s1 == BLANK or gram.s2 == BLANK) continue;
            const bigram = BiGram{ .s0 = gram.s1, .s1 = gram.s2 };
            const gop2 = self.bi_gram_counts.getOrPutValue(bigram, 0) catch {
                std.debug.print("!!! CANNOT PUT VALUE TO bi_gram_counts !!!", .{});
                unreachable;
            };
            gop2.value_ptr.* += 1;

            if (gram.s0 == BLANK) continue;
            const gop3 = self.tri_gram_counts.getOrPutValue(gram, 0) catch {
                std.debug.print("!!! CANNOT PUT VALUE TO tri_gram_counts !!!", .{});
                unreachable;
            };
            gop3.value_ptr.* += 1;
        } // while
        writeGramCounts(self.bi_gram_counts, bi_filename) catch {
            std.debug.print("!!! CANOT WRITE bi_gram_counts to {s} !!!", .{bi_filename});
            unreachable;
        };
        writeGramCounts(self.tri_gram_counts, tri_filename) catch {
            std.debug.print("!!! CANOT WRITE tri_gram_counts to {s} !!!", .{tri_filename});
            unreachable;
        };

        self.bi_gram_counts.deinit();
        self.tri_gram_counts.deinit();
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

    var min_count: u8 = NGram.MIN_COUNT;
    if (grams.count() < 100_000) min_count = 1;

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

        if (count < min_count) continue;

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

    var file = try std.fs.cwd().createFile("data/tknz.txt", .{});
    defer file.close();
    var buff_wrt = Text.BufferedWriter{ .unbuffered_writer = file.writer() };
    text.writer = buff_wrt.writer();

    var it = std.mem.tokenize(u8, text.input_bytes, " ");
    var attrs: Text.TokenAttributes = .{
        .category = .alphmark,
        .surrounded_by_spaces = .both,
    };
    while (it.next()) |tkn| {
        try text.recordToken(tkn, attrs, false);
    }

    text.tokens_number_finalized = true;
    text_utils.parseTokens(&text);

    try buff_wrt.flush();

    gram.parseAndWriteFourGram(text, "data/temp4.txt");
    gram.parseAndWriteBiTriGram(text, "data/temp2.txt", "data/temp3.txt");
}
