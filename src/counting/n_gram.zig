// Dùng hash_map thông thường để count và lưu keys cho chuẩn
// 1-gram U: 11621, U12: 0, U345: 0, U6+: 11621, T: 175122458, M: 26847026
// 2-gram U: 2665234, U12: 1444334, U345: 424429, U6+: 796471, T: 175122455, M: 414990
// 3-gram U: 17299599, U12: 13300885, U345: 1995402, U6+: 2003312, T: 121428409, M: 128152
// 4-gram U: 38698245, U12: 33285765, U345: 3114767, U6+: 2297713, T: 116712862, M: 56755
// (( STEP 3: Count and write n-gram done! Duration 1.39 mins ))

// TODO: Kết hợp với BinaryFuse để tăng tốc và giảm dung lượng lưu trũ

const std = @import("std");
const mem = std.mem;

const Text = @import("../textoken/text_data_struct.zig").Text;
const Syllable = @import("../phoneme/syllable_data_structs.zig").Syllable;

const Gram = Syllable.UniqueId;
const BLANK: Gram = Syllable.NONE_ID;
const SyllableIdArray = std.ArrayList(Syllable.UniqueId);

pub fn NGram() type {
    return struct {
        c1_grams: std.AutoHashMap([1]Gram, u32) = undefined,
        c2_grams: std.AutoHashMap([2]Gram, u32) = undefined,
        c3_grams: std.AutoHashMap([3]Gram, u32) = undefined,
        c4_grams: std.AutoHashMap([4]Gram, u32) = undefined,

        syllable_ids: SyllableIdArray = undefined,
        allocator: std.mem.Allocator = undefined,

        const Self = @This();

        pub fn init(self: *Self, init_allocator: std.mem.Allocator) void {
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

            while (i < n) : (i += 1) {
                var char = input_bytes[i];
                if (char >= 24) {
                    char = input_bytes[i + 1];
                    syll_id = char_to_index[char] << 12;

                    char = input_bytes[i + 2];
                    syll_id |= char_to_index[char] << 6;

                    i += 3;
                    char = input_bytes[i];
                    syll_id |= char_to_index[char];

                    try self.syllable_ids.append(syll_id);
                    in_blank_zone = false;
                    //
                } else if (!in_blank_zone) {
                    try self.syllable_ids.append(BLANK);
                    in_blank_zone = true;
                }
            }

            try self.syllable_ids.append(BLANK);
        }

        pub fn deinit(self: *Self) void {
            self.syllable_ids.deinit();
        }

        pub fn countAndWrite(
            self: *Self,
            comptime filename1: []const u8,
            comptime filename2: []const u8,
            comptime filename3: []const u8,
            comptime filename4: []const u8,
        ) !void {
            //

            try self.syllable_ids.append(BLANK);
            try self.syllable_ids.append(BLANK);
            try self.syllable_ids.append(BLANK);
            try self.syllable_ids.append(BLANK);

            const n = self.syllable_ids.items.len;
            const _percents: u8 = 5;
            const _percents_delta = (n * _percents / 100);
            var percents_threshold = _percents_delta;
            var percents: u8 = 0;

            self.c1_grams = std.AutoHashMap([1]Gram, u32).init(self.allocator);
            self.c2_grams = std.AutoHashMap([2]Gram, u32).init(self.allocator);
            self.c3_grams = std.AutoHashMap([3]Gram, u32).init(self.allocator);
            self.c4_grams = std.AutoHashMap([4]Gram, u32).init(self.allocator);

            var i: usize = 5;
            const syll_ids = self.syllable_ids.items;
            var grams: [4]Gram = .{ 0, syll_ids[0], syll_ids[1], syll_ids[2] };

            var tmp: [2048]Gram = undefined;
            var buf = tmp[0..];

            while (i < n) : (i += 2048) {
                var max = i + 2048;
                if (max > n) max = n;
                std.mem.copy(Gram, buf, syll_ids[i..max]);

                // Show progress
                if (max > percents_threshold) {
                    percents += _percents;
                    percents_threshold += _percents_delta;
                    std.debug.print("Counting 1..4-grams {d}%\n", .{percents});
                }

                for (buf[0 .. max - i]) |syll_id| {
                    grams[0] = grams[1];
                    grams[1] = grams[2];
                    grams[2] = grams[3];
                    grams[3] = syll_id;

                    const gop1 = try self.c1_grams.getOrPutValue(.{grams[0]}, 0);
                    gop1.value_ptr.* += 1;

                    if (grams[0] == BLANK) {
                        if (grams[1] == BLANK) continue;
                        const gop2 = try self.c2_grams.getOrPutValue(grams[0..2].*, 0);
                        gop2.value_ptr.* += 1;

                        if (grams[2] == BLANK) continue;
                        const gop3 = try self.c3_grams.getOrPutValue(grams[0..3].*, 0);
                        gop3.value_ptr.* += 1;

                        if (grams[3] == BLANK) continue;
                        const gop4 = try self.c4_grams.getOrPutValue(grams[0..4].*, 0);
                        gop4.value_ptr.* += 1;
                    } else { // grams[0] != BLANK
                        //
                        const gop2 = try self.c2_grams.getOrPutValue(grams[0..2].*, 0);
                        gop2.value_ptr.* += 1;

                        if (grams[1] == BLANK or grams[2] == BLANK) continue;
                        const gop3 = try self.c3_grams.getOrPutValue(grams[0..3].*, 0);
                        gop3.value_ptr.* += 1;

                        if (grams[2] == BLANK) continue;
                        const gop4 = try self.c4_grams.getOrPutValue(grams[0..4].*, 0);
                        gop4.value_ptr.* += 1;
                    }
                } // for syll_id
            } // while

            try writeGramCounts(self.c1_grams, filename1, 1);
            self.c1_grams.deinit();

            try writeGramCounts(self.c2_grams, filename2, 2);
            self.c2_grams.deinit();

            try writeGramCounts(self.c3_grams, filename3, 3);
            self.c3_grams.deinit();

            try writeGramCounts(self.c4_grams, filename4, 4);
            self.c4_grams.deinit();
        }
    };
}

fn writeGramCounts(grams: anytype, comptime filename: []const u8, n: u8) !void {
    var file = try std.fs.cwd().createFile(filename ++ ".bin", .{});
    defer file.close();

    var f12 = try std.fs.cwd().createFile(filename ++ ".012", .{});
    defer f12.close();

    var f345 = try std.fs.cwd().createFile(filename ++ ".345", .{});
    defer f345.close();

    var wrt = std.io.bufferedWriter(file.writer());
    var writer = wrt.writer();

    var f12_wrt = std.io.bufferedWriter(f12.writer());
    var f12_writer = f12_wrt.writer();

    var f345_wrt = std.io.bufferedWriter(f345.writer());
    var f345_writer = f345_wrt.writer();

    var total: usize = 0;
    var t12: usize = 0;
    var t345: usize = 0;
    var len: u32 = 0;
    var max: u32 = 0;
    var count: u32 = undefined;

    var it = grams.iterator();
    while (it.next()) |kv| {
        count = kv.value_ptr.*;
        total += count;
        len += 1;
        if (count > max) max = count;

        if (n == 1) { // 1-gram
            _ = try writer.write(std.mem.asBytes(&count));
            _ = try writer.write(std.mem.asBytes(&kv.key_ptr));
        } else { // 2,3,4-gram
            switch (count) {
                1, 2 => {
                    t12 += 1;
                    _ = try f12_writer.write(std.mem.asBytes(&kv.key_ptr));
                },
                3, 4, 5 => {
                    t345 += 1;
                    _ = try f345_writer.write(std.mem.asBytes(&kv.key_ptr));
                },
                else => {
                    _ = try writer.write(std.mem.asBytes(&kv.key_ptr));
                },
            }
        }
    }

    try wrt.flush();
    try f12_wrt.flush();
    try f345_wrt.flush();

    std.debug.print("\n{}-gram U: {}, U12: {}, U345: {}, U6+: {}, T: {}, M: {}", .{ n, len, t12, t345, len - t12 - t345, total, max });
}

test "ngram" {
    const text_utils = @import("../textoken/text_utils.zig");
    var gram: NGram() = .{};
    // gram.init(std.testing.allocator);
    gram.init(std.heap.page_allocator);
    defer gram.deinit();

    var text = Text{
        // .init_allocator = std.testing.allocator,
        .init_allocator = std.heap.page_allocator,
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

    try gram.countAndWrite(
        "data/temp.n1",
        "data/temp.n2",
        "data/temp.n3",
        "data/temp.n4",
    );
}
