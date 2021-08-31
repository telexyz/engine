// ORIGINAL IMPL
// - - - - - - - - - - - - - - - - - - - - - - - - - - -
// data/21-uni_grams.txt UNIQ: 11620, COUNT: 148275434 <<
// data/22-bi_grams.txt UNIQ: 2665233, COUNT: 175122466 <<
// data/23-tri_grams.txt UNIQ: 18224608, COUNT: 143989170 <<
// data/24-fourth_grams.txt UNIQ: 38698237, COUNT: 116712854 <<
// data/25-fifth_grams.txt UNIQ: 49032659, COUNT: 95921019 <<
// data/26-sixth_grams.txt UNIQ: 49381015, COUNT: 78262936 <<
// (( Count and write n-gram done! Duration 2.89 mins ))

// NEW IMPL BASED ON ROBIN-HOOD OPEN ADDRESS
// - - - - - - - - - - - - - - - - - - - - - - - - - - -
// data/21-grams.txt UNIQ: 11620,    COUNT: 148275434 <<
// data/22-grams.txt UNIQ: 2666021 , COUNT: 175111766 <<
// data/23-grams.txt UNIQ: 18228070, COUNT: 143967960 <<
// data/24-grams.txt UNIQ: 38701828, COUNT: 116689547 <<
// data/25-grams.txt UNIQ: 49034514, COUNT: 95912168 <<
// data/26-grams.txt UNIQ: 49381937, COUNT: 78259053 <<
// (( Count and write n-gram done! Duration 2.22 mins ))

// - - - - - - - - - - - - - - - - - - - - - - - - - - -
// u32 cityhash, u22 Fnv1a as fingerprint
// - - - - - - - - - - - - - - - - - - - - - - - - - - -
// data/21-grams.cdx UNIQ: 11620,    COUNT: 148275434 <<
// data/22-grams.cdx UNIQ: 2666021,  COUNT: 175111767 <<
// data/23-grams.cdx UNIQ: 18228071, COUNT: 143967962 <<
// data/24-grams.cdx UNIQ: 38701829, COUNT: 116689548 <<
// data/25-grams.cdx UNIQ: 49034515, COUNT: 95912169 <<
// data/26-grams.cdx UNIQ: 49381938, COUNT: 78259054 <<
// (( Count and write n-gram done! Duration 1.40 mins ))
// Total: 158_023_994
// 2^27 = 134_217_728, => 4-grams: 35m, 5: 39m, 6: 39m
// perf tốt hơn nếu max load ~80%
// tức là 110_000_000 => Cần xoá thêm 14m nữa
// - - - - - - - - - - - - - - - - - - - - - - - - - - -
const MAX_4_GRAMs: u32 = 33_000_000;
const MAX_5_GRAMs: u32 = 33_000_000;
const MAX_6_GRAMs: u32 = 33_000_000;

// - - - - - - - - - - -
//  119 KB  21-grams.txt
//   39 MB  22-grams.txt
//  371 MB  23-grams.txt
// 1012 MB  24-grams.txt
//  1.5 GB  25-grams.txt
//  1.9 GB  26-grams.txt
//  2.0 GB  27-grams.txt
//  1.9 GB  28-grams.txt
// - - - - - - - - - - - - - - - -
// n   type   bytes  mem     count
// - - - - - - - - - - - - - - - -
// 1                        148.3m
// 2   2.7m x 11 =  30mb    175.1m
// 3  18.2m x 13 = 237mb    144.0m
// 4  38.7m x 15 = 581mb    116.7m
// 5  49.0m x 17 = 833mb     95.9m
// 6  49.4m x 19 = 939mb     78.3m
// - - - - - - - - - - - - - - - -
//   158.0m 2..6-grams (~1.3Gb)
// - - - - - - - - - - - - - - - -
// 7  44.6m x 21 = 937mb     63.9m
// 8  38.3m x 23 = 881mb     52.1m
// - - - - - - - - - - - - - - - -
//   241.0m 2..8-grams (~2.6Gb)
// - - - - - - - - - - - - - - - -

const std = @import("std");
const Text = @import("../textoken/text_data_struct.zig").Text;
const Syllable = @import("../phoneme/syllable_data_structs.zig").Syllable;
const HashCount = @import("./hash_count.zig").HashCount;

const Gram = Syllable.UniqueId;
const BLANK: Gram = Syllable.NONE_ID;

pub fn NGram(for_real: bool) type {
    return struct {
        // Làm tròn thành powerOfTwo để đảm bảo thứ tự tăng dần của hash values
        c1_grams: HashCount([1]Gram, if (!for_real) 64 else 16_384) = undefined,
        c2_grams: HashCount([2]Gram, if (!for_real) 64 else 4_194_304) = undefined,
        c3_grams: HashCount([3]Gram, if (!for_real) 64 else 33_554_432) = undefined, //2^25
        c4_grams: HashCount([4]Gram, if (!for_real) 64 else 67_108_864) = undefined, //2^26
        c5_grams: HashCount([5]Gram, if (!for_real) 64 else 67_108_864) = undefined, //2^26
        c6_grams: HashCount([6]Gram, if (!for_real) 64 else 67_108_864) = undefined, //2^26

        allocator: *std.mem.Allocator = undefined,

        const Self = @This();

        pub fn init(self: *Self, init_allocator: *std.mem.Allocator) void {
            self.allocator = init_allocator;
        }

        pub fn deinit(self: *Self) void {
            _ = self;
        }

        const PAD = "\n                        ";
        pub fn countAndWrite23(self: *Self, text: Text, filename2: []const u8, filename3: []const u8) !void {
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
                    std.debug.print("\nCounting 2,3-gram {d}%", .{percents});
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

            try writeGramCounts(self.c2_grams, filename2, 2);
            self.c2_grams.deinit();

            try writeGramCounts(self.c3_grams, filename3, 3);
            self.c3_grams.deinit();
        }

        pub fn countAndWrite06(self: *Self, text: Text, filename6: []const u8) !void {
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
                    std.debug.print(PAD ++ "Counting 6-gram {d}%", .{percents});
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

            try writeGramCounts(self.c6_grams, filename6, 6);
            self.c6_grams.deinit();
        }

        pub fn countAndWrite15(self: *Self, text: Text, filename1: []const u8, filename5: []const u8) !void {
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
                    std.debug.print(PAD ++ "Counting 1,5-gram {d}%", .{percents});
                    percents_threshold += ten_percents;
                }

                grams[0] = grams[1];
                grams[1] = grams[2];
                grams[2] = grams[3];
                grams[3] = grams[4];
                grams[4] = syllable_ids[i];

                if (grams[4] != BLANK)
                    _ = self.c1_grams.put(.{grams[4]});

                if (!(grams[1] == BLANK or grams[2] == BLANK or grams[3] == BLANK) and
                    !(grams[0] == BLANK and grams[4] == BLANK))
                    _ = self.c5_grams.put(grams);
            }

            try writeGramCounts(self.c1_grams, filename1, 1);
            self.c1_grams.deinit();

            try writeGramCounts(self.c5_grams, filename5, 5);
            self.c5_grams.deinit();
        }

        pub fn countAndWrite04(self: *Self, text: Text, filename4: []const u8) !void {
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
                    std.debug.print("\nCounting 4-gram {d}%", .{percents});
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

            try writeGramCounts(self.c4_grams, filename4, 4);
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

const Base64Encoder = std.base64.standard_no_pad.Encoder; // standard vs standard_no_pad
pub fn writeGramCounts(grams: anytype, filename: []const u8, n: u8) !void {
    var buffer: [13]u8 = undefined;
    const buff = buffer[0..];

    var buffer2: [13]u8 = undefined;
    const buff2 = buffer2[0..];

    // Sort by count desc
    var items = grams.slice();

    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    var wrt = std.io.bufferedWriter(file.writer());
    var writer = wrt.writer();

    var total: usize = 0;

    var check_limit = (n >= 4);
    var limit: usize = switch (n) {
        else => 0,
        4 => MAX_4_GRAMs,
        5 => MAX_5_GRAMs,
        6 => MAX_6_GRAMs,
    };
    if (limit < grams.len) {
        limit = grams.len - limit;
    } else check_limit = false;

    for (items) |item|
        if (item.count >= 1) {
            total += item.count;
            if (check_limit and item.count == 1 and limit > 0) {
                limit -= 1;
                continue;
            }

            try writer.print("{d} {s} {s}\n", .{
                item.count,
                Base64Encoder.encode(buff, std.mem.asBytes(&item.hash)),
                Base64Encoder.encode(buff2, std.mem.asBytes(&item.fp)),
            });
        };

    try wrt.flush();
    std.debug.print("\n{s} UNIQ: {d}, COUNT: {d} <<", .{ filename, grams.len, total });
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

    try gram.countAndWrite15(text, "data/temp1.cdx", "data/temp5.cdx");
    try gram.countAndWrite23(text, "data/temp2.cdx", "data/temp3.cdx");
    try gram.countAndWrite04(text, "data/temp4.cdx");
    try gram.countAndWrite06(text, "data/temp6.cdx");
}
