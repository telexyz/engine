const std = @import("std");
const Text = @import("../textoken/text_data_struct.zig").Text;
const Syllable = @import("../phoneme/syllable_data_structs.zig").Syllable;
const Gram = Syllable.UniqueId;
const BLANK: Gram = Syllable.NONE_ID;
pub const MIN_COUNT = 10;

pub const NGram = struct {
    c1_grams: std.AutoHashMap([2]Gram, u32) = undefined,
    c2_grams: std.AutoHashMap([2]Gram, u32) = undefined,
    c3_grams: std.AutoHashMap([3]Gram, u32) = undefined,
    c4_grams: std.AutoHashMap([4]Gram, u32) = undefined,
    c5_grams: std.AutoHashMap([5]Gram, u32) = undefined,
    c6_grams: std.AutoHashMap([6]Gram, u32) = undefined,
    c7_grams: std.AutoHashMap([7]Gram, u32) = undefined,
    c8_grams: std.AutoHashMap([8]Gram, u32) = undefined,

    allocator: std.mem.Allocator = undefined,

    pub fn init(self: *NGram, init_allocator: std.mem.Allocator) void {
        self.allocator = init_allocator;
        self.c1_grams = std.AutoHashMap([2]Gram, u32).init(self.allocator);
        self.c2_grams = std.AutoHashMap([2]Gram, u32).init(self.allocator);
        self.c3_grams = std.AutoHashMap([3]Gram, u32).init(self.allocator);
        self.c4_grams = std.AutoHashMap([4]Gram, u32).init(self.allocator);
        self.c5_grams = std.AutoHashMap([5]Gram, u32).init(self.allocator);
        self.c6_grams = std.AutoHashMap([6]Gram, u32).init(self.allocator);
        self.c7_grams = std.AutoHashMap([7]Gram, u32).init(self.allocator);
        self.c8_grams = std.AutoHashMap([8]Gram, u32).init(self.allocator);
    }

    pub fn deinit(self: *NGram) void {
        _ = self;
    }

    const PAD = "                        ";

    pub fn countAndWrite236(self: *NGram, text: Text, filename2: []const u8, filename3: []const u8, filename6: []const u8) !void {
        // Record progress
        const ten_percents = text.tokens_num / 10;
        var percents_threshold = ten_percents;
        var percents: u8 = 0;

        var grams: [6]Gram = .{ BLANK, BLANK, BLANK, BLANK, BLANK, BLANK };
        var i: usize = 0;
        const syllable_ids = text.tokens_infos.items(.syllable_id);

        while (i < text.tokens_num) : (i += 1) {
            // Show progress
            if (i >= percents_threshold) {
                percents += 10;
                std.debug.print(PAD ++ "Counting 2,3,6-gram {d}%\n", .{percents});
                percents_threshold += ten_percents;
            }

            grams[0] = grams[1];
            grams[1] = grams[2];
            grams[2] = grams[3];
            grams[3] = grams[4];
            grams[4] = grams[5];
            grams[5] = syllable_ids[i];

            if (!(grams[4] == BLANK and grams[5] == BLANK)) {
                const gop2 = try self.c2_grams.getOrPutValue(grams[4..6].*, 0);
                gop2.value_ptr.* += 1;
            }

            if (!(grams[4] == BLANK) and
                !(grams[3] == BLANK and grams[5] == BLANK))
            {
                const gop3 = try self.c3_grams.getOrPutValue(grams[3..6].*, 0);
                gop3.value_ptr.* += 1;
            }

            if (grams[1] == BLANK or grams[2] == BLANK) continue;
            if (grams[3] == BLANK or grams[4] == BLANK) continue;
            if (grams[0] == BLANK and grams[5] == BLANK) continue;

            // const gop6 = try self.c6_grams.getOrPutValue(grams, 0);
            // gop6.value_ptr.* += 1;
        } // while

        try writeGramCounts(self.c2_grams, filename2, false);
        self.c2_grams.deinit();

        try writeGramCounts(self.c3_grams, filename3, false);
        self.c3_grams.deinit();

        _ = filename6;
        // try writeGramCounts(self.c6_grams, filename6, false);
        // self.c6_grams.deinit();
    }

    pub fn countAndWrite157(self: *NGram, text: Text, filename1: []const u8, filename5: []const u8, filename7: []const u8) !void {
        // Record progress
        const ten_percents = text.tokens_num / 10;
        var percents_threshold = ten_percents;
        var percents: u8 = 0;

        var grams: [7]Gram = .{ BLANK, BLANK, BLANK, BLANK, BLANK, BLANK, BLANK };
        var i: usize = 0;
        const syllable_ids = text.tokens_infos.items(.syllable_id);

        while (i < text.tokens_num) : (i += 1) {
            // Show progress
            if (i >= percents_threshold) {
                percents += 10;
                std.debug.print("Counting 1,5,7-gram {d}%\n", .{percents});
                percents_threshold += ten_percents;
            }

            grams[0] = grams[1];
            grams[1] = grams[2];
            grams[2] = grams[3];
            grams[3] = grams[4];
            grams[4] = grams[5];
            grams[5] = grams[6];
            grams[6] = syllable_ids[i];

            if (grams[6] != BLANK) {
                const gop1 = try self.c1_grams.getOrPutValue(.{ grams[6], BLANK }, 0);
                gop1.value_ptr.* += 1;
            }

            if (!(grams[3] == BLANK or grams[4] == BLANK or grams[5] == BLANK) and
                !(grams[2] == BLANK and grams[6] == BLANK))
            {
                const gop5 = try self.c5_grams.getOrPutValue(grams[2..7].*, 0);
                gop5.value_ptr.* += 1;
            }

            if (!(grams[1] == BLANK or grams[2] == BLANK or grams[3] == BLANK) and
                !(grams[4] == BLANK or grams[5] == BLANK) and
                !(grams[0] == BLANK and grams[6] == BLANK))
            {
                // const gop7 = try self.c7_grams.getOrPutValue(grams[0..7].*, 0);
                // gop7.value_ptr.* += 1;
            }
        }

        try writeGramCounts(self.c1_grams, filename1, true);
        self.c1_grams.deinit();

        try writeGramCounts(self.c5_grams, filename5, false);
        self.c5_grams.deinit();

        _ = filename7;
        // try writeGramCounts(self.c7_grams, filename7, false);
        // self.c7_grams.deinit();
    }

    pub fn countAndWrite48(self: *NGram, text: Text, filename4: []const u8, filename8: []const u8) !void {
        // Record progress
        const ten_percents = text.tokens_num / 10;
        var percents_threshold = ten_percents;
        var percents: u8 = 0;

        var grams: [8]Gram = .{ BLANK, BLANK, BLANK, BLANK, BLANK, BLANK, BLANK, BLANK };
        var i: usize = 0;
        const syllable_ids = text.tokens_infos.items(.syllable_id);

        while (i < text.tokens_num) : (i += 1) {
            // Show progress
            if (i >= percents_threshold) {
                percents += 10;
                std.debug.print(PAD ++ PAD ++ "Counting 4,8-gram {d}%\n", .{percents});
                percents_threshold += ten_percents;
            }

            grams[0] = grams[1];
            grams[1] = grams[2];
            grams[2] = grams[3];
            grams[3] = grams[4];
            grams[4] = grams[5];
            grams[5] = grams[6];
            grams[6] = grams[7];
            grams[7] = syllable_ids[i];

            if (!(grams[5] == BLANK or grams[6] == BLANK) and
                !(grams[4] == BLANK and grams[7] == BLANK))
            {
                const gop4 = try self.c4_grams.getOrPutValue(grams[4..8].*, 0);
                gop4.value_ptr.* += 1;
            }

            if (grams[1] == BLANK or grams[2] == BLANK or grams[3] == BLANK) continue;
            if (grams[4] == BLANK or grams[5] == BLANK or grams[6] == BLANK) continue;
            if (grams[0] == BLANK and grams[7] == BLANK) continue;

            // const gop8 = try self.c8_grams.getOrPutValue(grams[0..8].*, 0);
            // gop8.value_ptr.* += 1;
        }

        try writeGramCounts(self.c4_grams, filename4, false);
        self.c4_grams.deinit();

        _ = filename8;
        // try writeGramCounts(self.c8_grams, filename8, false);
        // self.c8_grams.deinit();
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

pub fn writeGramCounts(grams: anytype, filename: []const u8, uniGram: bool) !void {
    var buffer: [13]u8 = undefined;
    const buff = buffer[0..];

    var min_count: u8 = MIN_COUNT;
    if (grams.count() < 100_000) min_count = 1;

    var grams_list = try std.ArrayList(GramInfo).initCapacity(
        std.heap.page_allocator,
        grams.count(),
    );
    defer grams_list.deinit();

    // Add items
    var it = grams.iterator();
    var total: usize = 0;
    var count: u32 = undefined;

    while (it.next()) |kv| {
        count = kv.value_ptr.*;
        total += count;

        if (count < min_count) continue;

        try grams_list.append(.{
            .grams = kv.key_ptr,
            .count = count,
        });
    } // while

    std.debug.print("\n{s} UNIQ: {d}, COUNT: {d} <<\n", .{ filename, grams.count(), total });

    // Sort by count desc
    std.sort.sort(GramInfo, grams_list.items, {}, order_by_count_desc);

    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    var wrt = std.io.bufferedWriter(file.writer());
    var writer = wrt.writer();

    for (grams_list.items) |item| {
        var id: Gram = item.grams[0];
        if (id == BLANK)
            try writer.print("{d} #", .{item.count})
        else
            try writer.print("{d} {s}", .{
                item.count,
                Syllable.newFromId(id).printBuff(buff, false),
            });

        if (uniGram) {
            _ = try writer.write("\n");
            continue;
        }

        var i: u8 = 1;
        while (i < item.grams.len) : (i += 1) {
            id = item.grams[i];
            if (id == BLANK)
                _ = try writer.write(" #")
            else
                try writer.print(" {s}", .{Syllable.newFromId(id).printBuff(buff, false)});
        }

        _ = try writer.write("\n");
    }

    try wrt.flush();
}

test "ngram" {
    const text_utils = @import("../textoken/text_utils.zig");
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
        .fenced_by_spaces = .both,
    };
    while (it.next()) |tkn| {
        try text.recordToken(tkn, attrs, false);
    }

    text.tokens_num_finalized = true;
    text_utils.parseTokens(&text);

    try gram.countAndWrite157(text, "data/temp1.txt", "data/temp5.txt", "data/temp7.txt");
    try gram.countAndWrite236(text, "data/temp2.txt", "data/temp3.txt", "data/temp6.txt");
    try gram.countAndWrite48(text, "data/temp4.txt", "data/temp8.txt");
}
