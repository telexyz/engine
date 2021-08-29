// - - - - - - - - - - - - - - - - - -
// MIN_COUNT = 2
// - - - - - - - - - - - - - - - - - -
// 119 KB  21-uni_grams.txt
//  24 MB  22-bi_grams.txt
// 139 MB  23-tri_grams.txt
// 258 MB  24-fourth_grams.txt
// 287 MB  25-fifth_grams.txt
// 269 MB  26-sixth_grams.txt
// 243 MB  27-seventh_grams.txt
// 221 MB  28-eighth_grams.txt
// - - - - - - - - - - - - - - - - - -
// n    type     mem             count
// - - - - - - - - - - - - - - - - - -
// 1                            148.3m
// 2 x  1.6m =   3.2 |          175.1m
// 3 x  6.8m =  20.4 |          144.0m
// 4 x  9.8m =  39.2 |          116.7m
// 5 x  8.8m =  48.0 |           96.9m
// 6 x  6.9m =  41.4 |           78.3m
// 7 x  5.3m =  37.1 |           63.9m
// 8 x  4.2m =  33.6 |           52.1m
// - - - - - - - - - - - - - - - - - -
//     43.4m n-grams

// - - - - - - - - - - - - - - - - - -
// MIN_COUNT = 1
// - - - - - - - - - - - - - - - - - -
//  119 KB  21-uni_grams.txt
//   39 MB  22-bi_grams.txt
//  371 MB  23-tri_grams.txt
// 1012 MB  24-fourth_grams.txt
//  1.5 GB  25-fifth_grams.txt
//  1.9 GB  26-sixth_grams.txt
//  2.0 GB  27-seventh_grams.txt
//  1.9 GB  28-eighth_grams.txt
// - - - - - - - - - - - - - - - - - -
// n    type     mem             count
// - - - - - - - - - - - - - - - - - -
// 1                            148.3m
// 2 x  2.7m =   5.4 |          175.1m
// 3 x 18.2m =  54.6 |          144.0m
// 4 x 38.7m = 154.8 |          116.7m
// 5 x 49.0m = 245.0 |           96.9m
// 6 x 49.4m = 296.4 |           78.3m
// 7 x 44.6m = 312.2 |           63.9m
// 8 x 38.3m = 306.4 |           52.1m
// - - - - - - - - - - - - - - - - - -
//    241.0m n-grams

const std = @import("std");
const Text = @import("../textoken/text_data_struct.zig").Text;
const Syllable = @import("../phoneme/syllable_data_structs.zig").Syllable;
const HashCount = @import("./hash_count.zig").HashCount;

const Gram = Syllable.UniqueId;
const BLANK: Gram = Syllable.NONE_ID;

pub fn NGram(for_real: bool) type {
    _ = for_real;

    return struct {
        c1_grams: HashCount([2]Gram, if (!for_real) 512 else 13_000) = undefined,
        c2_grams: HashCount([2]Gram, if (!for_real) 512 else 3_000_000) = undefined,
        c3_grams: HashCount([3]Gram, if (!for_real) 512 else 19_000_000) = undefined,
        c4_grams: HashCount([4]Gram, if (!for_real) 512 else 40_000_000) = undefined,
        c5_grams: HashCount([5]Gram, if (!for_real) 512 else 50_000_000) = undefined,
        c6_grams: HashCount([6]Gram, if (!for_real) 512 else 50_000_000) = undefined,

        // c1_grams: HashCount([2]Gram, if (!for_real) 512 else 16_384) = undefined,
        // c2_grams: HashCount([2]Gram, if (!for_real) 512 else 4_194_304) = undefined,
        // c3_grams: HashCount([3]Gram, if (!for_real) 512 else 33_554_432) = undefined,
        // c4_grams: HashCount([4]Gram, if (!for_real) 512 else 67_108_864) = undefined,
        // c5_grams: HashCount([5]Gram, if (!for_real) 512 else 67_108_864) = undefined,
        // c6_grams: HashCount([6]Gram, if (!for_real) 512 else 67_108_864) = undefined,

        allocator: *std.mem.Allocator = undefined,

        const Self = @This();

        pub fn init(self: *Self, init_allocator: *std.mem.Allocator) void {
            self.allocator = init_allocator;
        }

        pub fn deinit(self: *Self) void {
            _ = self;
        }

        const PAD = "                        ";

        pub fn parseAndWrite23Gram(self: *Self, text: Text, filename2: []const u8, filename3: []const u8) !void {
            // Record progress
            const ten_percents = text.tokens_num / 10;
            var percents_threshold = ten_percents;
            var percents: u8 = 0;

            try self.c2_grams.init(self.allocator);
            try self.c3_grams.init(self.allocator);

            var grams: [3]Gram = .{ BLANK, BLANK, BLANK };
            var i: usize = 0;
            const syllable_ids = text.tokens_infos.items(.syllable_id);

            while (i < text.tokens_num) : (i += 1) {
                // Show progress
                if (i >= percents_threshold) {
                    percents += 10;
                    std.debug.print("Parsing 2,3-gram {d}%\n", .{percents});
                    percents_threshold += ten_percents;
                }

                grams[0] = grams[1];
                grams[1] = grams[2];
                grams[2] = syllable_ids[i];

                if (!(grams[1] == BLANK and grams[2] == BLANK))
                    _ = self.c2_grams.put(grams[1..3].*);

                if (!(grams[1] == BLANK) and
                    !(grams[0] == BLANK and grams[2] == BLANK))
                    _ = self.c3_grams.put(grams);
            } // while

            try writeGramCounts(self.c2_grams, filename2, false);
            self.c2_grams.deinit();

            try writeGramCounts(self.c3_grams, filename3, false);
            self.c3_grams.deinit();
        }

        pub fn parseAndWrite06Gram(self: *Self, text: Text, filename6: []const u8) !void {
            // Record progress
            const ten_percents = text.tokens_num / 10;
            var percents_threshold = ten_percents;
            var percents: u8 = 0;

            try self.c6_grams.init(self.allocator);

            var grams: [6]Gram = .{ BLANK, BLANK, BLANK, BLANK, BLANK, BLANK };
            var i: usize = 0;
            const syllable_ids = text.tokens_infos.items(.syllable_id);

            while (i < text.tokens_num) : (i += 1) {
                // Show progress
                if (i >= percents_threshold) {
                    percents += 10;
                    std.debug.print(PAD ++ "Parsing 6-gram {d}%\n", .{percents});
                    percents_threshold += ten_percents;
                }

                grams[0] = grams[1];
                grams[1] = grams[2];
                grams[2] = grams[3];
                grams[3] = grams[4];
                grams[4] = grams[5];
                grams[5] = syllable_ids[i];

                if (grams[1] == BLANK or grams[2] == BLANK) continue;
                if (grams[3] == BLANK or grams[4] == BLANK) continue;
                if (grams[0] == BLANK and grams[5] == BLANK) continue;
                _ = self.c6_grams.put(grams);
            } // while

            try writeGramCounts(self.c6_grams, filename6, false);
            self.c6_grams.deinit();
        }

        pub fn parseAndWrite15Gram(self: *Self, text: Text, filename1: []const u8, filename5: []const u8) !void {
            // Record progress
            const ten_percents = text.tokens_num / 10;
            var percents_threshold = ten_percents;
            var percents: u8 = 0;

            try self.c1_grams.init(self.allocator);
            try self.c5_grams.init(self.allocator);

            var grams: [5]Gram = .{ BLANK, BLANK, BLANK, BLANK, BLANK };
            var i: usize = 0;
            const syllable_ids = text.tokens_infos.items(.syllable_id);

            while (i < text.tokens_num) : (i += 1) {
                // Show progress
                if (i >= percents_threshold) {
                    percents += 10;
                    std.debug.print(PAD ++ "Parsing 1,5-gram {d}%\n", .{percents});
                    percents_threshold += ten_percents;
                }

                grams[0] = grams[1];
                grams[1] = grams[2];
                grams[2] = grams[3];
                grams[3] = grams[4];
                grams[4] = syllable_ids[i];

                if (grams[4] != BLANK)
                    _ = self.c1_grams.put(.{ grams[4], BLANK });

                if (!(grams[1] == BLANK or grams[2] == BLANK or grams[3] == BLANK) and
                    !(grams[0] == BLANK and grams[4] == BLANK))
                    _ = self.c5_grams.put(grams);
            }

            try writeGramCounts(self.c1_grams, filename1, true);
            self.c1_grams.deinit();

            try writeGramCounts(self.c5_grams, filename5, false);
            self.c5_grams.deinit();
        }

        pub fn parseAndWrite04Gram(self: *Self, text: Text, filename4: []const u8) !void {
            // Record progress
            const ten_percents = text.tokens_num / 10;
            var percents_threshold = ten_percents;
            var percents: u8 = 0;

            try self.c4_grams.init(self.allocator);

            var grams: [4]Gram = .{ BLANK, BLANK, BLANK, BLANK };
            var i: usize = 0;
            const syllable_ids = text.tokens_infos.items(.syllable_id);

            while (i < text.tokens_num) : (i += 1) {
                // Show progress
                if (i >= percents_threshold) {
                    percents += 10;
                    std.debug.print("Parsing 4-gram {d}%\n", .{percents});
                    percents_threshold += ten_percents;
                }

                grams[0] = grams[1];
                grams[1] = grams[2];
                grams[2] = grams[3];
                grams[3] = syllable_ids[i];

                if (!(grams[1] == BLANK or grams[2] == BLANK) and
                    !(grams[0] == BLANK and grams[3] == BLANK))
                    _ = self.c4_grams.put(grams);
            }

            try writeGramCounts(self.c4_grams, filename4, false);
            self.c4_grams.deinit();
        }
    };
}

fn orderFn(comptime T: type) type {
    return struct {
        pub fn order_by_count_desc(context: void, a: T, b: T) bool {
            _ = context;
            return a.count > b.count;
        }
    };
}

pub fn writeGramCounts(grams: anytype, filename: []const u8, uniGram: bool) !void {
    var buffer: [13]u8 = undefined;
    const buff = buffer[0..];

    var min_count: u24 = 1;

    // Sort by count desc
    var items = grams.slice();
    const Entry = @TypeOf(grams).Entry;
    std.sort.sort(Entry, items, {}, orderFn(Entry).order_by_count_desc);

    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    var wrt = std.io.bufferedWriter(file.writer());
    var writer = wrt.writer();

    var total: usize = 0;

    for (items) |item| {
        if (item.count == 0) break;

        total += item.count;
        if (item.count < min_count) continue;

        var id: Gram = item.key[0];
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
        while (i < item.key.len) : (i += 1) {
            id = item.key[i];
            if (id == BLANK)
                _ = try writer.write(" #")
            else
                try writer.print(" {s}", .{Syllable.newFromId(id).printBuff(buff, false)});
        }

        _ = try writer.write("\n");
    }

    try wrt.flush();

    std.debug.print("\n>> {s} TOKENS COUNT {d} <<\n", .{ filename, total });
}

test "ngram" {
    const text_utils = @import("../textoken/text_utils.zig");
    var gram: NGram(false) = .{};
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

    try gram.parseAndWrite15Gram(text, "data/temp1.txt", "data/temp5.txt");
    try gram.parseAndWrite23Gram(text, "data/temp2.txt", "data/temp3.txt");
    try gram.parseAndWrite04Gram(text, "data/temp4.txt");
    try gram.parseAndWrite06Gram(text, "data/temp6.txt");
}
