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
const AutoHashCount = @import("./hash_count.zig").AutoHashCount;

const Gram = Syllable.UniqueId;
const BLANK: Gram = Syllable.NONE_ID;

pub const NGram = struct {
    c1_grams: AutoHashCount([2]Gram, 16_384) = undefined, //     2^14
    c2_grams: AutoHashCount([2]Gram, 4_194_304) = undefined, //  2^22
    c3_grams: AutoHashCount([3]Gram, 33_554_432) = undefined, // 2^25
    c4_grams: AutoHashCount([4]Gram, 67_108_864) = undefined, // 2^26
    c5_grams: AutoHashCount([5]Gram, 67_108_864) = undefined,
    c6_grams: AutoHashCount([6]Gram, 67_108_864) = undefined,
    c7_grams: AutoHashCount([7]Gram, 67_108_864) = undefined,
    c8_grams: AutoHashCount([8]Gram, 67_108_864) = undefined,

    allocator: *std.mem.Allocator = undefined,

    pub const MIN_COUNT = 2;

    pub fn init(self: *NGram, init_allocator: *std.mem.Allocator) void {
        self.allocator = init_allocator;
    }

    pub fn deinit(self: *NGram) void {
        _ = self;
    }

    const PAD = "                        ";

    pub fn parseAndWrite236Gram(self: *NGram, text: Text, filename2: []const u8, filename3: []const u8, filename6: []const u8) !void {
        // Record progress
        const ten_percents = text.tokens_num / 10;
        var percents_threshold = ten_percents;
        var percents: u8 = 0;

        try self.c2_grams.init(self.allocator);
        try self.c3_grams.init(self.allocator);
        try self.c6_grams.init(self.allocator);

        var grams: [6]Gram = .{ BLANK, BLANK, BLANK, BLANK, BLANK, BLANK };
        var i: usize = 0;
        const syllable_ids = text.tokens_infos.items(.syllable_id);

        while (i < text.tokens_num) : (i += 1) {
            // Show progress
            if (i >= percents_threshold) {
                percents += 10;
                std.debug.print(PAD ++ "Parsing 2,3,6-gram {d}%\n", .{percents});
                percents_threshold += ten_percents;
            }

            grams[0] = grams[1];
            grams[1] = grams[2];
            grams[2] = grams[3];
            grams[3] = grams[4];
            grams[4] = grams[5];
            grams[5] = syllable_ids[i];

            if (!(grams[4] == BLANK and grams[5] == BLANK))
                _ = self.c2_grams.put(grams[4..6].*);

            if (!(grams[4] == BLANK) and
                !(grams[3] == BLANK and grams[5] == BLANK))
                _ = self.c3_grams.put(grams[3..6].*);

            if (grams[1] == BLANK or grams[2] == BLANK) continue;
            if (grams[3] == BLANK or grams[4] == BLANK) continue;
            if (grams[0] == BLANK and grams[5] == BLANK) continue;
            _ = self.c6_grams.put(grams);
        } // while

        try writeGramCounts(self.c2_grams, filename2, false);
        self.c2_grams.deinit();

        try writeGramCounts(self.c3_grams, filename3, false);
        self.c3_grams.deinit();

        try writeGramCounts(self.c6_grams, filename6, false);
        self.c6_grams.deinit();
    }

    pub fn parseAndWrite157Gram(self: *NGram, text: Text, filename1: []const u8, filename5: []const u8, filename7: []const u8) !void {
        // Record progress
        const ten_percents = text.tokens_num / 10;
        var percents_threshold = ten_percents;
        var percents: u8 = 0;

        try self.c1_grams.init(self.allocator);
        try self.c5_grams.init(self.allocator);
        try self.c7_grams.init(self.allocator);

        var grams: [7]Gram = .{ BLANK, BLANK, BLANK, BLANK, BLANK, BLANK, BLANK };
        var i: usize = 0;
        const syllable_ids = text.tokens_infos.items(.syllable_id);

        while (i < text.tokens_num) : (i += 1) {
            // Show progress
            if (i >= percents_threshold) {
                percents += 10;
                std.debug.print("Parsing 1,5,7-gram {d}%\n", .{percents});
                percents_threshold += ten_percents;
            }

            grams[0] = grams[1];
            grams[1] = grams[2];
            grams[2] = grams[3];
            grams[3] = grams[4];
            grams[4] = grams[5];
            grams[5] = grams[6];
            grams[6] = syllable_ids[i];

            if (grams[6] != BLANK)
                _ = self.c1_grams.put(.{ grams[6], BLANK });

            if (!(grams[3] == BLANK or grams[4] == BLANK or grams[5] == BLANK) and
                !(grams[2] == BLANK and grams[6] == BLANK))
                _ = self.c5_grams.put(grams[2..7].*);

            if (!(grams[1] == BLANK or grams[2] == BLANK or grams[3] == BLANK) and
                !(grams[4] == BLANK or grams[5] == BLANK) and
                !(grams[0] == BLANK and grams[6] == BLANK))
                _ = self.c7_grams.put(grams[0..7].*);
        }

        try writeGramCounts(self.c1_grams, filename1, true);
        self.c1_grams.deinit();

        try writeGramCounts(self.c5_grams, filename5, false);
        self.c5_grams.deinit();

        try writeGramCounts(self.c7_grams, filename7, false);
        self.c7_grams.deinit();
    }

    pub fn parseAndWrite48Gram(self: *NGram, text: Text, filename4: []const u8, filename8: []const u8) !void {
        // Record progress
        const ten_percents = text.tokens_num / 10;
        var percents_threshold = ten_percents;
        var percents: u8 = 0;

        try self.c4_grams.init(self.allocator);
        try self.c8_grams.init(self.allocator);

        var grams: [8]Gram = .{ BLANK, BLANK, BLANK, BLANK, BLANK, BLANK, BLANK, BLANK };
        var i: usize = 0;
        const syllable_ids = text.tokens_infos.items(.syllable_id);

        while (i < text.tokens_num) : (i += 1) {
            // Show progress
            if (i >= percents_threshold) {
                percents += 10;
                std.debug.print(PAD ++ PAD ++ "Parsing 7,8-gram {d}%\n", .{percents});
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
                _ = self.c4_grams.put(grams[4..8].*);

            if (grams[1] == BLANK or grams[2] == BLANK or grams[3] == BLANK) continue;
            if (grams[4] == BLANK or grams[5] == BLANK or grams[6] == BLANK) continue;
            if (grams[0] == BLANK and grams[7] == BLANK) continue;
            _ = self.c8_grams.put(grams[0..8].*);
        }

        try writeGramCounts(self.c4_grams, filename4, false);
        self.c4_grams.deinit();

        try writeGramCounts(self.c8_grams, filename8, false);
        self.c8_grams.deinit();
    }
};

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

    var min_count: u8 = NGram.MIN_COUNT;
    if (grams.len < 100_000) min_count = 1;

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

    try gram.parseAndWrite157Gram(text, "data/temp1.txt", "data/temp5.txt", "data/temp7.txt");
    try gram.parseAndWrite236Gram(text, "data/temp2.txt", "data/temp3.txt", "data/temp6.txt");
    try gram.parseAndWrite48Gram(text, "data/temp4.txt", "data/temp8.txt");
}
