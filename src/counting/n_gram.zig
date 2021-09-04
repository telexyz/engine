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

// u32 cityhash, u22 Fnv1a as fingerprint
// - - - - - - - - - - - - - - - - - - - - - - - - - - -
// data/21-grams.bin UNIQ: 11620,    COUNT: 148275434 <<
// data/22-grams.bin UNIQ: 2666021,  COUNT: 175111767 <<
// data/23-grams.bin UNIQ: 18228071, COUNT: 143967962 <<
// data/24-grams.bin UNIQ: 38701829, COUNT: 116689548 <<
// data/25-grams.bin UNIQ: 49034515, COUNT: 95912169 <<
// data/26-grams.bin UNIQ: 49381938, COUNT: 78259054 <<
// (( Count and write n-gram done! Duration 1.36 mins ))

// - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Total: 158_023_994 1..6-grams
// 2^27 = 134_217_728, => 4-grams: 35m, 5: 39m, 6: 39m
// perf tốt hơn nếu max load ~80%
// tức là khoảng 111_000_000 => Cần xoá thêm 23m nữa
// - - - - - - - - - - - - - - - - - - - - - - - - - - -
const LIMIT_4_GRAM: u32 = 30_000_000;
const LIMIT_5_GRAM: u32 = 30_000_000;
const LIMIT_6_GRAM: u32 = 30_000_000;

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
const Base64Encoder = std.base64.standard_no_pad.Encoder;

const Text = @import("../textoken/text_data_struct.zig").Text;
const Syllable = @import("../phoneme/syllable_data_structs.zig").Syllable;
const HashCount = @import("./hash_count.zig").HashCount;

const Gram = Syllable.UniqueId;
const BLANK: Gram = Syllable.NONE_ID;
const SyllableIdArray = std.ArrayList(Syllable.UniqueId);

pub fn NGram(for_real: bool) type {
    return struct {
        // Làm tròn thành powerOfTwo để đảm bảo thứ tự tăng dần của hash values
        c1_grams: HashCount([1]Gram, if (!for_real) 64 else 16_384) = undefined,
        c2_grams: HashCount([2]Gram, if (!for_real) 64 else 4_194_304) = undefined,
        c3_grams: HashCount([3]Gram, if (!for_real) 64 else 33_554_432) = undefined, //2^25
        c4_grams: HashCount([4]Gram, if (!for_real) 64 else 67_108_864) = undefined, //2^26
        c5_grams: HashCount([5]Gram, if (!for_real) 64 else 67_108_864) = undefined, //2^26
        c6_grams: HashCount([6]Gram, if (!for_real) 64 else 67_108_864) = undefined, //2^26

        syllable_ids: SyllableIdArray = undefined,

        allocator: *std.mem.Allocator = undefined,

        const Self = @This();

        pub fn init(self: *Self, init_allocator: *std.mem.Allocator) void {
            self.allocator = init_allocator;
        }

        pub fn loadSyllableIdsFromText(self: *Self, text: Text) !void {
            const syll_ids = text.tokens_infos.items(.syllable_id);
            self.syllable_ids = try SyllableIdArray.initCapacity(
                self.allocator,
                syll_ids.len * 3 / 2,
            );

            var prev_syll_id: Syllable.UniqueId = BLANK;
            try self.syllable_ids.append(BLANK);

            for (syll_ids) |syll_id| {
                if (syll_id == BLANK and prev_syll_id == BLANK) continue;
                try self.syllable_ids.append(syll_id);
                prev_syll_id = syll_id;
            }

            try self.syllable_ids.append(BLANK);
        }

        pub fn loadSyllableIdsCdxFile(self: *Self, filename: []const u8) !void {
            var file = try std.fs.cwd().openFile(filename, .{ .read = true });
            defer file.close();

            const input_bytes = try file.reader().readAllAlloc(
                self.allocator,
                1024 * 1024 * 1024,
            ); // max 1Gb
            defer self.allocator.free(input_bytes);

            const n = input_bytes.len;
            self.syllable_ids = try SyllableIdArray.initCapacity(self.allocator, n / 6);

            // Decode base64
            var char_to_index = [_]Syllable.UniqueId{0xff} ** 256;
            for (std.base64.standard_alphabet_chars) |c, i|
                char_to_index[c] = @intCast(Syllable.UniqueId, i);

            // Init syllable_ids from bytes
            var in_blank_zone = true;
            try self.syllable_ids.append(BLANK);

            var syll_id: Syllable.UniqueId = undefined;
            var i: usize = 0;
            var idx: Syllable.UniqueId = undefined;

            // var buffer: [13]u8 = undefined;
            // const buff = buffer[0..];
            while (i < n) : (i += 1) {
                // if (i > 100) break; //DEBUG
                if (input_bytes[i] > 32) {
                    // std.debug.print("\n{d}/{d}: {s} |", .{ i, n, input_bytes[i .. i + 3] }); //DEBUG

                    idx = char_to_index[input_bytes[i]];
                    // std.debug.print(" {s}:{} ", .{ input_bytes[i .. i + 1], idx });
                    if (idx > 63) unreachable;
                    syll_id = idx << 12;

                    i += 1;
                    idx = char_to_index[input_bytes[i]];
                    // std.debug.print(" {s}:{} ", .{ input_bytes[i .. i + 1], idx });
                    if (idx > 63) unreachable;
                    syll_id |= idx << 6;

                    i += 1;
                    idx = char_to_index[input_bytes[i]];
                    // std.debug.print(" {s}:{} ", .{ input_bytes[i .. i + 1], idx });
                    if (idx > 63) unreachable;
                    syll_id |= idx;

                    try self.syllable_ids.append(syll_id);
                    in_blank_zone = false;

                    // std.debug.print("=> {s}", .{Syllable.newFromId(syll_id).printBuffUtf8(buff)}); //DEBUG
                    //
                } else if (input_bytes[i] < 0x1a and !in_blank_zone) {
                    //
                    // std.debug.print("\n", .{}); //DEBUG
                    try self.syllable_ids.append(BLANK);
                    in_blank_zone = true;
                }
            }

            try self.syllable_ids.append(BLANK);
        }

        pub fn deinit(self: *Self) void {
            self.syllable_ids.deinit();
        }

        const PAD = "\n                        ";
        pub fn countAndWrite23(self: *Self, filename2: []const u8, filename3: []const u8) !void {
            const syllable_ids = self.syllable_ids.items;
            const ten_percents = syllable_ids.len / 10;
            var percents_threshold = ten_percents;
            var percents: u8 = 0;

            try self.c2_grams.init(self.allocator);
            try self.c3_grams.init(self.allocator);

            var grams: [3]Gram = .{ BLANK, BLANK, BLANK };
            var i: usize = 0;

            while (i < syllable_ids.len) : (i += 1) {
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

        pub fn countAndWrite06(self: *Self, filename6: []const u8) !void {
            const syllable_ids = self.syllable_ids.items;
            const ten_percents = syllable_ids.len / 10;
            var percents_threshold = ten_percents;
            var percents: u8 = 0;

            try self.c6_grams.init(self.allocator);

            var grams: [6]Gram = .{ BLANK, BLANK, BLANK, BLANK, BLANK, BLANK };
            var i: usize = 0;

            while (i < syllable_ids.len) : (i += 1) {
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

        pub fn countAndWrite15(self: *Self, filename1: []const u8, filename5: []const u8) !void {
            const syllable_ids = self.syllable_ids.items;
            const ten_percents = syllable_ids.len / 10;
            var percents_threshold = ten_percents;
            var percents: u8 = 0;

            try self.c1_grams.init(self.allocator);
            try self.c5_grams.init(self.allocator);

            var grams: [5]Gram = .{ BLANK, BLANK, BLANK, BLANK, BLANK };
            var i: usize = 0;

            while (i < syllable_ids.len) : (i += 1) {
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

        pub fn countAndWrite04(self: *Self, filename4: []const u8) !void {
            const syllable_ids = self.syllable_ids.items;
            const ten_percents = syllable_ids.len / 10;
            var percents_threshold = ten_percents;
            var percents: u8 = 0;

            try self.c4_grams.init(self.allocator);

            var grams: [4]Gram = .{ BLANK, BLANK, BLANK, BLANK };
            var i: usize = 0;

            while (i < syllable_ids.len) : (i += 1) {
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

pub fn writeGramCounts(grams: anytype, filename: []const u8, n: u8) !void {
    var items = grams.slice();

    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();

    var wrt = std.io.bufferedWriter(file.writer());
    var writer = wrt.writer();

    // var buffer: [13]u8 = undefined;
    // const buff = buffer[0..];

    var total: usize = 0;
    var maxx: u24 = 1;

    var check_limit = (n >= 4);
    var limit: usize = switch (n) {
        else => 0,
        4 => LIMIT_4_GRAM,
        5 => LIMIT_5_GRAM,
        6 => LIMIT_6_GRAM,
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

            if (item.count > maxx) maxx = item.count;

            _ = try writer.write(std.mem.asBytes(&item.count));
            _ = try writer.write(std.mem.asBytes(&item.keyRepresent()));
            // try writer.print("{d} {s}\n", .{
            //     item.count,
            //     Base64Encoder.encode(buff, std.mem.asBytes(&item.keyRepresent())),
            // });
        };

    try wrt.flush();
    std.debug.print("\n{s} UNIQ: {d}, COUNT: {d}, MAXX: {d} <<", .{ filename, grams.len, total, maxx });
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
    try gram.loadSyllableIdsFromText(text);

    try gram.countAndWrite15("data/temp1.bin", "data/temp5.bin");
    try gram.countAndWrite23("data/temp2.bin", "data/temp3.bin");
    try gram.countAndWrite04("data/temp4.bin");
    try gram.countAndWrite06("data/temp6.bin");
}
