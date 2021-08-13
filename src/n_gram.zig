// REF https://kheafield.com/code/kenlm

const std = @import("std");
const Text = @import("./text_data_struct.zig").Text;
const Syllable = @import("./syllable_data_structs.zig").Syllable;
const Gram = Syllable.UniqueId;
const BLANK: Gram = 0;

pub const NGram = struct {
    c1_grams: std.AutoHashMap([2]Gram, u32) = undefined,
    c2_grams: std.AutoHashMap([2]Gram, u32) = undefined,
    c3_grams: std.AutoHashMap([3]Gram, u32) = undefined,
    c4_grams: std.AutoHashMap([4]Gram, u32) = undefined,
    c5_grams: std.AutoHashMap([5]Gram, u32) = undefined,
    c6_grams: std.AutoHashMap([6]Gram, u32) = undefined,

    allocator: *std.mem.Allocator = undefined,

    pub const MIN_COUNT = 5;

    pub fn init(self: *NGram, init_allocator: *std.mem.Allocator) void {
        self.allocator = init_allocator;
        self.c1_grams = std.AutoHashMap([2]Gram, u32).init(self.allocator);
        self.c2_grams = std.AutoHashMap([2]Gram, u32).init(self.allocator);
        self.c3_grams = std.AutoHashMap([3]Gram, u32).init(self.allocator);
        self.c4_grams = std.AutoHashMap([4]Gram, u32).init(self.allocator);
        self.c5_grams = std.AutoHashMap([5]Gram, u32).init(self.allocator);
        self.c6_grams = std.AutoHashMap([6]Gram, u32).init(self.allocator);
    }

    pub fn deinit(self: *NGram) void {
        _ = self;
        // self.c2_grams.deinit();
        // self.c3_grams.deinit();
        // self.c4_grams.deinit();
        // self.c5_grams.deinit();
        // self.c6_grams.deinit();
    }

    const PAD = "                        ";

    pub fn parseAndWrite123Gram(self: *NGram, text: Text, filename1: []const u8, filename2: []const u8, filename3: []const u8) !void {
        // Record progress
        const ten_percents = text.tokens_number / 10;
        var percents_threshold = ten_percents;
        var percents: u8 = 0;
        var grams: [3]Gram = .{ BLANK, BLANK, BLANK };

        var i: usize = 0;
        while (i < text.tokens_number) : (i += 1) {
            // Show progress
            if (i >= percents_threshold) {
                percents += 10;
                std.debug.print("{s}{d}% Parsing 1,2,3-gram\n", .{ PAD, percents });
                percents_threshold += ten_percents;
            }

            grams[0] = grams[1];
            grams[1] = grams[2];
            grams[2] = text.tokens_infos[i].syllable_id;

            if (grams[2] == BLANK) continue;
            const gop1 = try self.c1_grams.getOrPutValue(.{ grams[2], 0 }, 0);
            gop1.value_ptr.* += 1;

            if (grams[1] == BLANK) continue;
            const gop2 = try self.c2_grams.getOrPutValue(grams[1..3].*, 0);
            gop2.value_ptr.* += 1;

            if (grams[0] == BLANK) continue;
            const gop3 = try self.c3_grams.getOrPutValue(grams, 0);
            gop3.value_ptr.* += 1;
        } // while

        try writeGramCounts(self.c1_grams, filename1);
        self.c1_grams.deinit();

        try writeGramCounts(self.c2_grams, filename2);
        self.c2_grams.deinit();

        try writeGramCounts(self.c3_grams, filename3);
        self.c3_grams.deinit();
    }

    pub fn parseAndWrite456Gram(self: *NGram, text: Text, filename4: []const u8, filename5: []const u8, filename6: []const u8) !void {
        // Record progress
        const ten_percents = text.tokens_number / 10;
        var percents_threshold = ten_percents;
        var percents: u8 = 0;

        var grams: [6]Gram = .{ BLANK, BLANK, BLANK, BLANK, BLANK, BLANK };
        var i: usize = 0;

        while (i < text.tokens_number) : (i += 1) {
            // Show progress
            if (i >= percents_threshold) {
                percents += 10;
                std.debug.print("Parsing 4,5,6-gram {d}%\n", .{percents});
                percents_threshold += ten_percents;
            }

            grams[0] = grams[1];
            grams[1] = grams[2];
            grams[2] = grams[3];
            grams[3] = grams[4];
            grams[4] = grams[5];
            grams[5] = text.tokens_infos[i].syllable_id;

            if (grams[2] == BLANK or grams[3] == BLANK) continue;
            if (grams[4] == BLANK or grams[5] == BLANK) continue;
            const gop4 = try self.c4_grams.getOrPutValue(grams[2..6].*, 0);
            gop4.value_ptr.* += 1;

            if (grams[1] == BLANK) continue;
            const gop5 = try self.c5_grams.getOrPutValue(grams[1..6].*, 0);
            gop5.value_ptr.* += 1;

            if (grams[0] == BLANK) continue;
            const gop6 = try self.c6_grams.getOrPutValue(grams, 0);
            gop6.value_ptr.* += 1;
        }

        try writeGramCounts(self.c4_grams, filename4);
        self.c4_grams.deinit();

        try writeGramCounts(self.c5_grams, filename5);
        self.c5_grams.deinit();

        try writeGramCounts(self.c6_grams, filename6);
        self.c6_grams.deinit();
    }
};

fn order_by_count_desc(context: void, a: GramInfo, b: GramInfo) bool {
    _ = context;
    return a.count > b.count;
}

const GramInfo = struct {
    grams: []const Gram,
    count: u32,
};

pub fn writeGramCounts(grams: anytype, filename: []const u8) !void {
    var buffer: [13]u8 = undefined;
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
        const count = kv.value_ptr.*;
        if (count < min_count) continue;
        try grams_list.append(.{
            .grams = kv.key_ptr,
            .count = count,
        });
    } // while

    // Sort by count desc
    std.sort.sort(GramInfo, grams_list.items, {}, order_by_count_desc);

    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    var wrt = std.io.bufferedWriter(file.writer());
    var writer = wrt.writer();

    for (grams_list.items) |item| {
        try writer.print("{d} {s}", .{
            item.count,
            Syllable.newFromId(item.grams[0]).printBuffUtf8(buff),
        });

        var i: u8 = 1;
        while (i < item.grams.len) : (i += 1) {
            const id: Gram = item.grams[i];
            if (id == 0) continue;
            try writer.print(" {s}", .{Syllable.newFromId(id).printBuffUtf8(buff)});
        }

        _ = try writer.write("\n");
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

    try gram.parseAndWrite123Gram(text, "data/temp1.txt", "data/temp2.txt", "data/temp3.txt");
    try gram.parseAndWrite456Gram(text, "data/temp4.txt", "data/temp5.txt", "data/temp6.txt");
}
